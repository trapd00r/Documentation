#include "opt.h"

#include <string.h>

int opt_ind;
int opt_err;
const char *opt_arg;
static const char *nextchar;

int opt_get(int argc, char *const *argv, const char *opts) {
	const char *p;

	if (!nextchar || !*nextchar) {
		if (opt_ind < argc)
			++opt_ind;
		if (opt_ind >= argc || argv[opt_ind][0] != '-' || !argv[opt_ind][1]) {
			return -1;
		}
		if (argv[opt_ind][1] == '-' && argv[opt_ind][2] == '\0') {
			++opt_ind;
			return -1;
		}
		nextchar = argv[opt_ind] + 1;
	}

	if ((p = strchr(opts, *nextchar)) && (*p != ':' || p == opts)) {
		if (p[1] == ':') {
			if (nextchar[1]) {
				opt_arg = nextchar + 1;
			} else if (opt_ind + 1 >= argc) {
				opt_arg = NULL;
			} else {
				opt_arg = argv[++opt_ind];
			}
			nextchar = NULL;
		} else {
			++nextchar;
		}
		return p[0];
	}

	opt_err = *nextchar++;
	return '\0';
}

void opt_reset(void) {
	opt_ind = 0;
	nextchar = NULL;
}
