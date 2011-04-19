#include <stdio.h>

int main(void) {
	printf("%llu\n", ((unsigned long long (*)(void))"\x0f\x31\xc3")());
	return 0;
}
