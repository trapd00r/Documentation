#include "unspine.h"

#include <limits.h>
#include <unistd.h>
#include <stdlib.h>
#include <string.h>
#include <errno.h>
#include <sys/mman.h>
#include <malloc.h>

#if defined __GNUC__
#define ATTR(x) __attribute__(x)
#define NOT_GCC(x) ((void)0)
#else
#define ATTR(x)
#define NOT_GCC(x) x
#endif

#define MKID_(a, b, c) a ## b ## c
#define MKID(a, b, c) MKID_(a, b, c)

#define DO_ONCE(x) \
	do { \
		static int MKID(lock_, __LINE__, _); \
		if (!MKID(lock_, __LINE__, _)) { \
			MKID(lock_, __LINE__, _) = 1; \
			{x;} \
		} \
	} while (0)

#define STATIC_ASSERT(c) extern char MKID(sa, __LINE__, _static_assert)[!!(c) * 2 - 1]

#define BITSOF(x) (CHAR_BIT * sizeof (x))

#define NCONTAINERS(n, csize) (((n) - 1) / (csize) + 1)
#define MULTIPLE_OF(k, n) ((k) * NCONTAINERS(n, k))

static void ewrite(const char *s) {
	write(STDERR_FILENO, s, strlen(s));
}

ATTR((__noreturn__))
static void die(const char *msg) {
	ewrite(msg);
	abort();
}

ATTR((__noreturn__))
static void edie(const char *what) {
	ewrite(what);
	ewrite(": ");
	ewrite(strerror(errno));
	ewrite("\n");
	abort();
}

#define STR_(x) #x
#define STR(x) STR_(x)
#define my_assert(c) ((c) ? (void)0 : die(__FILE__ ":" STR(__LINE__) ": assertion failed: " #c "\n"))

enum {LOW_UNUSED = 3};
enum {ALIGN_MAX = 1 << LOW_UNUSED};

typedef struct FreeNode FreeNode;
struct FreeNode {
	FreeNode *next;
};

STATIC_ASSERT(sizeof (FreeNode) + 1 <= ALIGN_MAX);

typedef struct EntryPoint EntryPoint;
struct EntryPoint {
	FreeNode *ptr;
};

enum {ADDR_SPACE = 32};
enum {MAX_BITS = ADDR_SPACE - 2};

STATIC_ASSERT(MAX_BITS <= BITSOF(size_t));

enum {NBUCKETS = MAX_BITS - LOW_UNUSED};

static EntryPoint root[NBUCKETS];

STATIC_ASSERT(NBUCKETS <= UCHAR_MAX);

#define TAG_MMAP UCHAR_MAX

enum {MMAP_BONUS = MULTIPLE_OF(ALIGN_MAX, 1 + sizeof (size_t))};

static int
	m_top_pad = 1024 * 1024 * 2,
	m_mmap_threshold = 1024 * 1024,
	m_mmap_max = INT_MAX;

static int cur_mmapped;

static size_t free_size;
static unsigned char *free_mem;

static size_t pagesize = 4 * 1024;

#if 0

#define DBG
#define BONUS_CHECKS

static char buf[123];

static char digit2char(size_t d) {
	return d > 15
		? '?'
		: "0123456789abcdef"[d]
	;
}

static void xfmt_r(char **s, size_t n, size_t b) {
	if (n / b) {
		xfmt_r(s, n / b, b);
	}
	*(*s)++ = digit2char(n % b);
}

static void xfmt(char *s, size_t n, size_t b) {
	xfmt_r(&s, n, b);
	*s = '\0';
}

static char *fmt_ptr(const void *p) {
	buf[0] = '0';
	buf[1] = 'x';
	xfmt(buf + 2, (size_t)p, 16);
	return buf;
}

static char *fmt_num(size_t n) {
	xfmt(buf, n, 10);
	return buf;
}

#endif

ATTR((__constructor__))
static void init_vars(void) {
	pagesize = sysconf(_SC_PAGESIZE);
	#ifdef DBG
	ewrite("*** unspine ***\n");
	#endif
}

void *_us_malloc(size_t n) {
	#ifdef DBG
	ewrite("| _us_malloc(");
	ewrite(fmt_num(n));
	ewrite(")\n");
	#endif

	if (n == 0) {
		return NULL;
	}

	if ((m_mmap_threshold < 0 || n >= (size_t)m_mmap_threshold) && cur_mmapped < m_mmap_max) {
		unsigned char *ptr;
		size_t amt;
		NOT_GCC(DO_ONCE(init_vars()));
		amt = MULTIPLE_OF(pagesize, n + MMAP_BONUS);
		if (amt <= n) {
			/* overflow */
			errno = ENOMEM;
			return NULL;
		}
		ptr = mmap(
			NULL,
			amt,
			PROT_READ | PROT_WRITE | PROT_EXEC,
			MAP_PRIVATE | MAP_ANONYMOUS,
			-1,
			0
		);
		if (ptr != MAP_FAILED) {
			unsigned char *r = ptr + MMAP_BONUS;
			*(size_t *)ptr = amt;
			r[-1] = TAG_MMAP;
			++cur_mmapped;
			return r;
		}
	}

	{
		unsigned char u;
		size_t cur = (size_t)1 << LOW_UNUSED;
		for (u = 0; u < NBUCKETS; ++u, cur <<= 1) {
			if (cur - 1 >= n) {
				break;
			}
		}
		if (u >= NBUCKETS) {
			errno = ENOMEM;
			return NULL;
		}


		if (root[u].ptr) {
			FreeNode *ptr = root[u].ptr;
			root[u].ptr = ptr->next;
			return ptr;
		}

		if (free_size < cur) {
			size_t amt = MULTIPLE_OF(cur, m_top_pad) + cur;
			unsigned char *newbrk;

			if (!free_mem) {
				unsigned char *oldbrk = sbrk(0);
				size_t intbrk = (size_t)oldbrk;  /* hax */
				/* size_t delta = (ALIGN_MAX - (intbrk + 1) % ALIGN_MAX) % ALIGN_MAX; */
				size_t newintbrk = (intbrk + ALIGN_MAX) & ~(ALIGN_MAX - 1);
				/* newintbrk += delta; */
				newintbrk += 1;
				if (newintbrk < intbrk) {
					errno = ENOMEM;
					return NULL;
				}
				newbrk = (unsigned char *)newintbrk;
				if (brk(newbrk) != 0) {
					errno = ENOMEM;
					return NULL;
				}
				free_mem = newbrk;

				#if 0
				/* XXX */
				free_size = (unsigned char *)sbrk(0) - free_mem;
				#endif
			}

			#ifdef BONUS_CHECKS
			{
				/* XXX */
				unsigned char *curbrk = sbrk(0);
				my_assert(free_mem + free_size == curbrk);
			}
			#endif

			newbrk = free_mem + free_size + amt;
			if (newbrk <= free_mem) {
				/* overflow */
				errno = ENOMEM;
				return NULL;
			}
			if (
				brk(newbrk) != 0 && (
					amt <= cur || (
						amt = cur,
						newbrk = free_mem + free_size + amt,
						brk(newbrk) != 0
					)
				)
			) {
				return NULL;
			}
			free_size += amt;
			#ifdef BONUS_CHECKS
			{
				/* XXX */
				unsigned char *curbrk = sbrk(0);
				my_assert(free_mem + free_size == curbrk);
			}
			#endif

		}

		{
			unsigned char *p = free_mem;
			free_mem += cur;
			free_size -= cur;
			*p = u;
			return p + 1;
		}
	}
}

void *_us_realloc(void *ptr, size_t n) {
	unsigned char *p = ptr;

	#ifdef DBG
	ewrite("| _us_realloc(");
	ewrite(fmt_ptr(ptr));
	ewrite(", ");
	ewrite(fmt_num(n));
	ewrite(")\n");
	#endif

	if (!n) {
		_us_free(ptr);
		return NULL;
	}
	if (!ptr) {
		return _us_malloc(n);
	}

	{
		unsigned char tag = p[-1];
		size_t size;

		if (tag == TAG_MMAP) {
			p -= MMAP_BONUS;
			size = *(size_t *)p;

			if (n <= size - MMAP_BONUS) {
				size_t newsize = MULTIPLE_OF(pagesize, n + MMAP_BONUS);
				if (newsize < size) {
					if (munmap(p + newsize, size - newsize) != 0) {
						edie("munmap()");
					}
					*(size_t *)p = newsize;
				}
				return ptr;
			}

			{
				unsigned char *fresh = _us_malloc(n);
				if (fresh) {
					memcpy(fresh, ptr, size - MMAP_BONUS);
					_us_free(ptr);
				}
				return fresh;
			}
		}

		my_assert(tag < NBUCKETS);
		size = (size_t)1 << (LOW_UNUSED + tag);
		if (n <= size - 1) {
			if ((n + 1) << 2 <= size) {
				unsigned char *fresh = _us_malloc(n);
				if (fresh) {
					memcpy(fresh, ptr, n);
					_us_free(ptr);
					return fresh;
				}
			}
			return ptr;
		}

		{
			unsigned char *fresh = _us_malloc(n);
			if (fresh) {
				memcpy(fresh, ptr, size - 1);
				_us_free(ptr);
			}
			return fresh;
		}
	}
}

void _us_free(void *ptr) {
	#ifdef DBG
	ewrite("| _us_free(");
	ewrite(fmt_ptr(ptr));
	ewrite(")\n");
	#endif

	if (ptr) {
		unsigned char *p = ptr;
		unsigned char tag = p[-1];

		if (tag == TAG_MMAP) {
			size_t n;
			p -= MMAP_BONUS;
			n = *(size_t *)p;
			if (munmap(p, n) != 0) {
				edie("munmap()");
			}
			my_assert(cur_mmapped > 0);
			--cur_mmapped;
			return;
		}

		my_assert(tag < NBUCKETS);
		{
			FreeNode *hd = ptr;
			hd->next = root[tag].ptr;
			root[tag].ptr = hd;
		}
	}
}

int _us_mallopt(int param, int value) {
	switch (param) {
		default:
			errno = EINVAL;
			return -1;

		case M_TOP_PAD:
			if (value < 0) {
				errno = EINVAL;
				return -1;
			}
			m_top_pad = value;
			break;

		case M_MMAP_THRESHOLD:
			m_mmap_threshold = value;
			break;

		case M_MMAP_MAX:
			m_mmap_max = value;
			break;
	}
	return 0;
}
