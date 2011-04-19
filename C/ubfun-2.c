#include <stdlib.h>
#include <stdio.h>

int main(void) {
	int *p;
	p = malloc(10 * sizeof *p);
	free(p);
	if (p) {
		printf("ok\n");
	}
	return 0;
}
