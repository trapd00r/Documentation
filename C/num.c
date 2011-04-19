#include <stdio.h>
#include <stdlib.h>
#include <ctype.h>
#include <math.h>
#include <string.h>
#include <float.h>

static const char *Prog = "num";

static void oom(void) {
    fprintf(stderr, "%s: Out of memory\n", Prog);
    exit(EXIT_FAILURE);
}

static void *xmalloc(size_t n) {
    void *const p = malloc(n);
    if (!p) {
        oom();
    }
    return p;
}

static void *xrealloc(void *p, size_t n) {
    p = realloc(p, n);
    if (!p) {
        oom();
    }
    return p;
}

static void xfree(void *p) {
    free(p);
}

typedef struct {
    char *buf;
    size_t len, size;
    size_t off;
} t_str;

static void s_alloc(t_str *s) {
    s->buf = xmalloc(s->size = 200);
    s->len = s->off = 0;
}

static void s_free(t_str *s) {
    xfree(s->buf);
}

static void s_null(t_str *s) {
    s->off = s->len = 0;
}

static int s_at(const t_str *s, size_t n) {
    return n < s->len ? (unsigned char)s->buf[s->off + n] : EOF;
}

static size_t s_length(const t_str *s) {
    return s->len;
}

static void s_shift(t_str *s) {
    if (s_length(s)) {
        s->len -= 1;
        s->off += 1;
    }
}

static void s_shiftws(t_str *s) {
    while (isspace(s_at(s, 0))) {
        s_shift(s);
    }
}

static void s_cat_c(t_str *s, char c) {
    if (s->off + s->len >= s->size) {
        if (s->off) {
            memmove(s->buf, s->buf + s->off, s->len);
            s->off = 0;
        } else {
            s->buf = xrealloc(s->buf, s->size = s->size * 2 + 1);
        }
    }
    s->buf[s->off + s->len++] = c;
}

static const char *s_ptr(const t_str *s) {
    return s->buf + s->off;
}

static void s_assign_s(t_str *s, const char *t) {
    const size_t len = strlen(t);
    if (len > s->size) {
        s->buf = xrealloc(s->buf, s->size = len + 1);
    }
    memcpy(s->buf, t, len);
    s->off = 0;
    s->len = len;
}

static void s_reverse(t_str *s) {
    if (s->len) {
        char
            *a = s->buf + s->off,
            *b = s->buf + s->off + s->len - 1;
        for (; a < b; ++a, --b) {
            char c = *a;
            *a = *b;
            *b = c;
        }
    }
}

static const char xdigits[] = "0123456789" "abcdefghijklmnopqrstuvwxyz";

static const char *x_frombase(t_str *s, unsigned base, double *r) {
    double p;
    size_t i;
    int sign;
    const char *tmp;

    if (base < 2 || base > 36) {
        return "invalid base";
    }
    s_shiftws(s);

    sign = 0;
    if (s_at(s, 0) == '-') {
        sign = 1;
        s_shift(s);
    } else if (s_at(s, 0) == '+') {
        s_shift(s);
    }

    p = 0.0;
    for (i = 0; i < s_length(s); ++i) {
        if (
            (tmp = strchr(xdigits, tolower(s_at(s, i)))) &&
            (unsigned)(tmp - xdigits) < base
        ) {
            p *= base;
            p += tmp - xdigits;
        } else {
            break;
        }
    }

    if (i < s_length(s)) {
        if (s_at(s, i) == '.') {
            double shift = 1.0;

            for (++i; i < s_length(s); ++i) {
                if (
                    (tmp = strchr(xdigits, tolower(s_at(s, i)))) &&
                    (unsigned)(tmp - xdigits) < base
                ) {
                    shift *= base;
                    p *= base;
                    p += tmp - xdigits;
                } else {
                    break;
                }
            }

            p /= shift;
        }
    }

    if (sign) {
        p = -p;
    }
    *r = p;
    return NULL;
}

static const char *x_tobase(double p, unsigned base, t_str *s) {
    int sign;
    size_t i;

    if (base < 2 || base > 36) {
        return "invalid base";
    }

    sign = 0;
    if (p < 0.) {
        p = -p;
        sign = 1;
    }

    s_null(s);

    if (floor(p) < p) {
        double foo, bar;
        size_t rounds;

        foo = 1 + floor(log(pow(10, DBL_DIG)) / log(base));
        bar = p > 0. ? 1 + floor(log(p) / log(base)) : 0.;
        if (bar >= foo) {
            rounds = 0;
        } else {
            rounds = foo - bar;
        }

        for (i = 0; i < rounds; ++i) {
            p *= base;
            if (floor(p) >= p) {
                ++i;
                break;
            }
        }

        p = floor(p);
        while (i--) {
            int c;
            c = fmod(p, base);
            p = floor(p / base);
            if (c >= 0) {
                s_cat_c(s, xdigits[c]);
            }
        }
    }

    while (s_at(s, 0) == '0') {
        s_shift(s);
    }

    if (s_length(s)) {
        s_cat_c(s, '.');
    }

    while (p > 0.) {
        int c;
        c = fmod(p, base);
        p = floor(p / base);
        if (c >= 0) {
            s_cat_c(s, xdigits[c]);
        }
    }

    if (!s_length(s) || s_at(s, s_length(s) - 1) == '.') {
        s_cat_c(s, '0');
    }
    if (sign) {
        s_cat_c(s, '-');
    }

    return NULL;
}

int main(int argc, char **argv) {
    t_str s;
    double n;
    unsigned from, to;
    const char *tmp;

    if (argv[0] && argv[0][0]) {
        Prog = argv[0];
    }

    if (argc != 4) {
        fprintf(stderr, "Usage: %s FROM-BASE TO-BASE NUMBER\n", Prog);
        return EXIT_FAILURE;
    }

    from = strtoul(argv[1], NULL, 10);
    to   = strtoul(argv[2], NULL, 10);

    s_alloc(&s);
    s_assign_s(&s, argv[3]);

    if ((tmp = x_frombase(&s, from, &n))) {
        s_free(&s);
        fprintf(stderr, "%s: error: %s\n", Prog, tmp);
        return EXIT_FAILURE;
    }
    if ((tmp = x_tobase(n, to, &s))) {
        s_free(&s);
        fprintf(stderr, "%s: error: %s\n", Prog, tmp);
        return EXIT_FAILURE;
    }

    s_reverse(&s);
    s_cat_c(&s, '\0');

    puts(s_ptr(&s));

    s_free(&s);
    return 0;
}
