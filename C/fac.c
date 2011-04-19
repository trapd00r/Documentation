#include <stdio.h>
#include <stdlib.h>

static unsigned long fac(unsigned long n) {
	if (n < 2) {
		return 1;
	}
	return n * fac(n - 1);
}

int main(int argc, char **argv) {
	printf("%lu\n", fac(strtoul(argv[argc - 1], NULL, 10)));
	return 0;
}
