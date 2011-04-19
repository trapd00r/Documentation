#include <stdio.h>

int main(void) {
	short i;
	for (i = 0; i < 10; --i) {
		printf("%hd\n", i);
	}
	return 0;
}
