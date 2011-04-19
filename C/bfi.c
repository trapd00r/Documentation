#include <unistd.h>
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <errno.h>
#include <limits.h>

#define PROG_NAME "bfi"

#define COUNTOF(a) (sizeof (a) / sizeof *(a))

static const char *prog = PROG_NAME;

static unsigned long cells[32767];
static unsigned long eof = ~0lu, cellsize = 8;

typedef enum {
	INS_NOP,
	INS_GO_LEFT,
	INS_GO_RIGHT,
	INS_INCR,
	INS_DECR,
	INS_PUTC,
	INS_GETC,
	INS_WHILE,
	INS_WEND,
	INS_SET
} t_instruction;

typedef struct t_node t_node;

typedef union {
	size_t count;
	t_node *bro;
} t_bonus;

struct t_node {
	t_instruction action;
	t_bonus attr;
};

static void die(const char *what) {
	fprintf(stderr, "%s: %s: %s\n", prog, what, strerror(errno));
	exit(EXIT_FAILURE);
}

static t_instruction char2ins(char c) {
	switch (c) {
		default:  return INS_NOP;
		case '<': return INS_GO_LEFT;
		case '>': return INS_GO_RIGHT;
		case '-': return INS_DECR;
		case '+': return INS_INCR;
		case '.': return INS_PUTC;
		case ',': return INS_GETC;
		case '[': return INS_WHILE;
		case ']': return INS_WEND;
	}
}

static void push(t_node **block, size_t *len, size_t *siz, t_instruction ins) {
	if (ins == INS_NOP) {
		return;
	}

	if (
		*len &&
		ins != INS_WHILE &&
		ins != INS_WEND &&
		(*block)[*len - 1].action == ins
	) {
		(*block)[*len - 1].attr.count += 1;
		return;
	}

	if (
		ins == INS_WEND &&
		*len >= 2 && (
			(*block)[*len - 1].action == INS_DECR ||
			(*block)[*len - 1].action == INS_INCR
		) &&
		(*block)[*len - 1].attr.count == 1 &&
		(*block)[*len - 2].action == INS_WHILE
	) {
		t_node *const p = *block + *len - 2;
		*len -= 1;
		p->action = INS_SET;
		p->attr.count = 0;
		return;
	}

	if (*len >= *siz) {
		t_node *tmp;
		if (!(tmp = realloc(*block, (*siz *= 2) * sizeof *tmp))) {
			free(*block);
			die("realloc()");
		}
		*block = tmp;
	}

	(*block)[*len].attr.count = 1;
	(*block)[*len].action = ins;
	*len += 1;
}

static t_node *find_end(t_node *start, const t_node *end) {
	t_node *p;
	for (p = start + 1; p < end; ++p) {
		if (p->action == INS_WEND) {
			start->attr.bro = p;
			p->attr.bro = start;
			return p;
		}
		if (p->action == INS_WHILE) {
			t_node *const tmp = find_end(p, end);
			if (!tmp) {
				return NULL;
			}
			p = tmp;
		}
	}
	return NULL;
}

static int connect(t_node *p, size_t len) {
	const t_node *const end = p + len;

	for (; p < end; ++p) {
		if (p->action == INS_WEND) {
			fprintf(stderr, "%s: unmatched ']'\n", prog);
			return -1;
		}
		if (p->action == INS_WHILE) {
			t_node *const tmp = find_end(p, end);
			if (!tmp) {
				fprintf(stderr, "%s: unmatched '['\n", prog);
				return -1;
			}
			p = tmp;
		}
	}

	return 0;
}

static unsigned long peek(size_t i) {
	size_t n = cells[i];
	if (cellsize >= CHAR_BIT * sizeof n) {
		return n;
	}
	return n & ((1lu << cellsize) - 1lu);
}

static void poke(size_t i, unsigned long n) {
	cells[i] = n;
}

static unsigned long xgetch(void) {
	int c = getchar();
	return c == EOF ? eof : (unsigned long)c;
}

static int interpret(const t_node *const start, size_t len) {
	const t_node *p = start;
	const t_node *const end = start + len;
	size_t i = 0;

	for (; p < end; ++p) {
		switch (p->action) {
			case INS_NOP:
				fprintf(stderr, "%s: internal error\n", prog);
				abort();

			case INS_GO_LEFT:
				if (i < p->attr.count) {
					fprintf(stderr, "%s: pointer out of range (-%lu)\n", prog, (unsigned long)(p->attr.count - i));
					return EXIT_FAILURE;
				}
				i -= p->attr.count;
				break;

			case INS_GO_RIGHT:
				if (COUNTOF(cells) - i - 1 < p->attr.count) {
					fprintf(stderr, "%s: pointer out of range (%lu)\n", prog, (unsigned long)(p->attr.count + i));
					return EXIT_FAILURE;
				}
				i += p->attr.count;
				break;

			case INS_DECR:
				poke(i, peek(i) - p->attr.count);
				break;

			case INS_INCR:
				poke(i, peek(i) + p->attr.count);
				break;

			case INS_PUTC: {
				size_t n;
				for (n = 0; n < p->attr.count; ++n) {
					putchar(peek(i));
				}
				break;
			}

			case INS_GETC: {
				size_t n;
				for (n = 0; n < p->attr.count; ++n) {
					poke(i, xgetch());
				}
				break;
			}

			case INS_WHILE:
				if (!peek(i)) {
					p = p->attr.bro;
				}
				break;

			case INS_WEND:
				if (peek(i)) {
					p = p->attr.bro;
				}
				break;

			case INS_SET:
				poke(i, p->attr.count);
				break;
		}
	}

	return 0;
}

static int collect_input(FILE *fp) {
	int c;
	size_t len, siz;
	t_node *block;

	len = 0;
	if (!(block = malloc((siz = 1003) * sizeof *block))) {
		die("malloc()");
	}

	while ((c = getc(fp)) != EOF) {
		push(&block, &len, &siz, char2ins(c));
	}

	if (connect(block, len)) {
		free(block);
		return EXIT_FAILURE;
	}

	return interpret(block, len);
}

int main(int argc, char **argv) {
	int c;
	FILE *fp;

	if (argv[0] && argv[0][0]) {
		prog = argv[0];
	}

	while ((c = getopt(argc, argv, "hc:e:f")) != -1) {
		switch (c) {
			case 'h':
				printf(
					"Usage: %s [OPTION...] [FILE]\n"
					"Options:\n"
					"  -h             print this help\n"
					"  -c NUMBER      specify cell size\n"
					"  -e NUMBER      specify EOF value\n"
					"  -f             enable autoflush\n"
					, prog
					);
				return EXIT_SUCCESS;

			case 'c':
				cellsize = strtoul(optarg, NULL, 0);
				break;

			case 'e':
				eof = strtol(optarg, NULL, 0);
				break;

			case 'f':
				setbuf(stdout, NULL);
				break;

			default:
				return EXIT_FAILURE;
		}
	}

	argc -= optind;
	argv += optind;

	if (!argv[0] || (argv[0][0] == '-' && argv[0][1] == '\0')) {
		fp = stdin;
	} else {
		if (!(fp = fopen(argv[0], "r"))) {
			die(argv[0]);
		}
	}

	return collect_input(fp);
}
