#define qnb "C Quine; Lukas Mai, 1.7.2004"
#include <stdio.h>
#define b "\\"
#define n "\n"
#define q "\""
#define bb "b"
#define nn "n"
#define qq "q"
#define bn "#define "
#define nb " "
#define bbb "#include <stdio.h>"
#define nnn "int main(void) { puts("
#define qqq "); return 0; }"
#define bnq "bn qq nn bb nb q qnb q n bbb n bn bb nb q b b q n bn nn nb q b nn q n bn qq nb q b q q n bn bb bb nb q bb q n bn nn nn nb q nn q n bn qq qq nb q qq q n bn bb nn nb q bn q n bn nn bb nb q nb q n bn bb bb bb nb q bbb q n bn nn nn nn nb q nnn q n bn qq qq qq nb q qqq q n bn bb nn qq nb q bnq q n nnn n bnq n qqq"
int main(void) { puts(
bn qq nn bb nb q qnb q n bbb n bn bb nb q b b q n bn nn nb q b nn q n bn qq nb q b q q n bn bb bb nb q bb q n bn nn nn nb q nn q n bn qq qq nb q qq q n bn bb nn nb q bn q n bn nn bb nb q nb q n bn bb bb bb nb q bbb q n bn nn nn nn nb q nnn q n bn qq qq qq nb q qqq q n bn bb nn qq nb q bnq q n nnn n bnq n qqq
); return 0; }
