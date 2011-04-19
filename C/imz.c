#include <unistd.h>
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <errno.h>
#include <time.h>
#include <math.h>

static const char *Prog = "imz";

static void usage(FILE *fp) {
	fprintf(fp,
			"Usage: %s [OPTION]...\n"
			"  --help     display this help\n"
			"  -w WIDTH   set width of the generated image\n"
			"  -h HEIGHT  set height of the generated image\n"
			"  -o FILE    write output to FILE instead of standard output\n"
			"\n"
			, Prog
	);
}

static void seed_rng(void) {
	FILE *fp;
	unsigned seed = 0;

	if ((fp = fopen("/dev/urandom", "rb"))) {
		fread(&seed, sizeof seed, 1, fp);
		fclose(fp);
	}
	if (!seed) {
		seed = time(NULL);
	}
	srand(seed);
}

static double xrand(void) {
	return rand() / (RAND_MAX + 1.0);
}

static double distance(long x1, long y1, long x2, long y2) {
	return hypot(x2 - x1, y2 - y1);
}

static unsigned char put_byte;
static size_t put_used;

static void putbit(FILE *fp, unsigned bit) {
	put_byte |= bit << (7 - put_used);
	++put_used;
	if (put_used >= 8) {
		putc(put_byte, fp);
		put_byte = '\0';
		put_used = 0;
	}
}

static void putflush(FILE *fp) {
	if (put_used) {
		putc(put_byte, fp);
		put_byte = '\0';
		put_used = 0;
	}
}

int main(int argc, char **argv) {
	int c;
	const char *outfile = NULL;
	unsigned long width = 640, height = 480;

	if (argv[0] && argv[0][0]) {
		Prog = argv[0];
	}

	while ((c = getopt(argc, argv, "h:w:o:")) != -1) {
		switch (c) {
			case 'h':
				if (strcmp(optarg, "elp") == 0) {
					usage(stdout);
					return EXIT_SUCCESS;
				}
				height = strtoul(optarg, NULL, 10);
				break;

			case 'w':
				width = strtoul(optarg, NULL, 10);
				break;

			case 'o':
				outfile = optarg;
				break;

			default:
				usage(stderr);
				return EXIT_FAILURE;
		}
	}

	{
		unsigned long p1x, p1y, p2x, p2y, x, y;
		FILE *fp = stdout;

		if (outfile && !(fp = fopen(outfile, "wb"))) {
			fprintf(stderr, "%s: %s: %s\n", Prog, outfile, strerror(errno));
			return EXIT_FAILURE;
		}
		if (!outfile) {
			outfile = "(stdout)";
		}

		seed_rng();

		p1x = xrand() * width;
		p1y = xrand() * height;
		p2x = xrand() * width;
		p2y = xrand() * height;

		fprintf(fp,
				"P4\n"
				"# generated by %s\n"
				"# p1 = (%lu,%lu); p2 = (%lu,%lu)\n"
				"%lu %lu\n"
				, Prog
				, p1x, p1y, p2x, p2y
				, width, height
		);

		for (y = 0; y < height; ++y) {
			for (x = 0; x < width; ++x) {
				putbit(fp, (unsigned long)(distance(p1x, p1y, x, y) * distance(p2x, p2y, x, y)) % 2);
			}
			putflush(fp);
		}

		if (fclose(fp)) {
			fprintf(stderr, "%s: %s: %s\n", Prog, outfile, strerror(errno));
			return EXIT_FAILURE;
		}
	}

	return EXIT_SUCCESS;
}
