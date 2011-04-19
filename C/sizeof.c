#include <stdio.h>

int main(void) {
	int n = sizeof(0)["abcdefghij"];
	printf("%d\n", n);
	return 0;
}
