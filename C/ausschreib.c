#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <errno.h>

static int well_formed(const char *s) {
	return *s && strspn(s, "0123456789") == strlen(s);
}

static const char *Prog = "ausschreib";

static void complain(const char *about, const char *reason) {
	fprintf(stderr, "%s: %s: %s\n", Prog, about, reason);
}

static char *getline(FILE *fp) {
	char *line;
	size_t size, length;
	int c;

	if (!(line = malloc(size = 120))) {
		complain("malloc() failed", strerror(errno));
		return NULL;
	}
	length = 0;
	while ((c = getc(fp)) != EOF && c != '\n') {
		if (length + 1u >= size) {
			char *const tmp = realloc(line, size * 2u);
			if (!tmp) {
				complain("realloc() failed", strerror(errno));
				free(line);
				return NULL;
			}
			line = tmp;
			size *= 2u;
		}
		line[length++] = c;
	}

	if (ferror(fp)) {
		complain("getc()", strerror(errno));
	}
	if (c == EOF && length == 0) {
		free(line);
		return NULL;
	}

	line[length] = '\0';
	return line;
}

static void say(const char *s) {
	static const char *num[][2] = {
		{ NULL, NULL },
		{ "ein",    "zehn"     },
		{ "zwei",   "zwanzig"  },
		{ "drei",   "dreissig" },
		{ "vier",   "vierzig"  },
		{ "fuenf",  "fuenfzig" },
		{ "sechs",  "sechzig"  },
		{ "sieben", "siebzig"  },
		{ "acht",   "achtzig"  },
		{ "neun",   "neunzig"  },
	};
	static const char *unit[] = {
		"tausend", "m", "b", "tr", "quadr", "quint", "sext", "sept",
		"okt", "non", "dez", "undez", "duodez", "tredez",
		"quattuordez", "quindez", "sexdez", "septendez", "oktodez",
		"novemdez", "vigint", "unvigint", "duovigint", "trevigint",
		"quattuorvigint", "quinvigint", "sexvigint", "septenvigint",
		"oktovigint", "novemvigint", "trigint", "untrigint",
		"duotrigint", "tretrigint", "quattuortrigint", "quintrigint",
		"sextrigint", "septentrigint", "oktotrigint", "novemtrigint",
		"quadragint", "unquadragint", "duoquadragint", "trequadragint",
		"quattuorquadragint", "quinquadragint", "sexquadragint",
		"septenquadragint", "oktoquadragint", "novemquadragint",
		"quinquagint",
	};

	size_t pos, len;
	int something = 0;
	int eins = 0;

	for (; *s == '0'; ++s)
		;
	if (!*s) {
		puts("null");
		return;
	}

	len = strlen(s);
	pos = 0;
	switch ((len - pos) % 3) {
		do {
			something = 0;
			eins = 0;

			putchar(' ');

		case 0:
			if (s[pos] != '0') {
				printf("%shundert", !pos && s[pos] == '1' ? "" : num[s[pos] - '0'][0]);
				something = 1;
			}
			++pos;

		case 2:
			if (s[pos] == '0') {
				++pos;

		case 1:
				if (s[pos] != '0') {
					printf("%s", num[s[pos] - '0'][0]);
					if (s[pos] == '1') {
						eins = 1;
					}
					something = 1;
				}
				++pos;

			} else {
				if (s[pos] == '1') {
					switch (s[pos + 1u]) {
						case '0': fputs("zehn", stdout);     break;
						case '1': fputs("elf", stdout);      break;
						case '2': fputs("zwoelf", stdout);   break;
						case '6': fputs("sechzehn", stdout); break;
						case '7': fputs("siebzehn", stdout); break;
						default:
								  printf("%s%s", num[s[pos + 1u] - '0'][0], num[s[pos] - '0'][1]);
								  break;
					}
				} else {
					if (s[pos + 1u] == '0') {
						fputs(num[s[pos] - '0'][1], stdout);
					} else {
						printf("%sund%s", num[s[pos + 1u] - '0'][0], num[s[pos] - '0'][1]);
					}
				}
				something = 1;
				pos += 2;
			}

			if (something) {
				if (pos >= len) {
					if (eins) {
						putchar('s');
					}
				} else {
					const size_t scale = (len - pos) / 3u;
					printf(
							"%s%s%s%s%s",
							!eins ? ""
							: scale > 1u ? "e"
							: scale < 1u ? "s"
							: "",
							scale == 1u ? "" : " ",
							scale / 2u >= sizeof unit / sizeof *unit
							? "<??\?>"
							: unit[scale / 2u],
							scale == 1u ? ""
							: scale % 2u ? "illiarde"
							: "illion",
							eins ? ""
							: scale == 1u ? ""
							: scale % 2u ? "n"
							: "en"
						  );
				}
			}
		} while (pos < len);
	}

	putchar('\n');
}

int main(int argc, char **argv) {
	int status = 0;

	if (argv[0] && argv[0][0]) {
		Prog = argv[0];
	}

	if (argc > 1) {
		int i;
		for (i = 1; i < argc; ++i) {
			if (!well_formed(argv[i])) {
				complain(argv[i], "malformed number");
				status = EXIT_FAILURE;
				continue;
			}

			say(argv[i]);
		}
	} else {
		char *line;

		while ((line = getline(stdin))) {
			if (!well_formed(line)) {
				complain(line, "malformed number");
				status = EXIT_FAILURE;
				free(line);
				continue;
			}

			say(line);
			free(line);
		}
		if (!feof(stdin)) {
			status = EXIT_FAILURE;
		}
	}

	return status;
}
