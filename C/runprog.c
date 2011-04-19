#include <stdio.h>
#include <string.h>
#include <errno.h>
#include <stdlib.h>
#include <signal.h>
#include <unistd.h>
#include <sys/resource.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <sys/wait.h>

#ifdef __GNUC__
#define ATTR(x) __attribute__((x))
#else
#define ATTR(x)
#endif

static const char *Prog = "runprog";

static void usage(FILE *fp) {
	fprintf(
		fp,
		"Usage: %s [OPTION...] PROG [ARG...]\n"
		"Available options:\n"
		"  -h          print this help\n"
		"  -i STRING   reopen stdin to STRING\n"
		"  -m BYTES    memory limit\n"
		"  -t SECONDS  time limit\n"
		, Prog
	);
}

ATTR(__noreturn__)
static void edie(const char *w) {
	fprintf(stderr, "%s: %s: %s\n", Prog, w, strerror(errno));
	exit(127);
}

static void handle(int signo, void (*f)(int)) {
	struct sigaction sa;
	sa.sa_handler = f;
	sa.sa_flags = SA_NOCLDSTOP;
	if (sigemptyset(&sa.sa_mask) == -1) {
		edie("sigemptyset()");
	}
	if (sigaction(signo, &sa, NULL) == -1) {
		edie("sigaction()");
	}
}

static void check(int sig) {
	switch (sig) {
		case SIGCHLD:
			exit(0);
	}
}

int main(int argc, char **argv) {
	if (argv[0] && argv[0][0]) {
		Prog = argv[0];
	}

	const char *input = NULL;
	rlim_t lmem = 1024 * 1024 * 50, ltime = 5;

	int c;
	while ((c = getopt(argc, argv, "+hi:m:t:")) != -1) {
		switch (c) {
			case 'h':
				usage(stdout);
				return 0;

			case 'i':
				input = optarg;
				break;

			case 'm':
				lmem = strtol(optarg, NULL, 0);
				break;

			case 't':
				ltime = strtol(optarg, NULL, 0);
				break;

			default:
				return 127;
		}
	}

	argc -= optind;
	argv += optind;

	if (argc <= 0) {
		usage(stderr);
		return 127;
	}

	int i;
	if ((i = open("/dev/null", O_RDONLY)) == -1) {
		i = 64;
	}
	for (; i > 2; --i) {
		close(i);
	}

	handle(SIGCHLD, check);
	handle(SIGALRM, check);

	pid_t pid = fork();
	switch (pid) {
		case -1:
			edie("fork()");

		case 0: {
			handle(SIGCHLD, SIG_DFL);
			handle(SIGALRM, SIG_DFL);

			if (input) {
				int p[2];
				if (pipe(p) == -1) {
					edie("pipe()");
				}
				switch (pid = fork()) {
					case -1:
						edie("fork()");

					case 0:
						switch (fork()) {
							case -1:
								edie("fork()");

							case 0:
								close(p[0]);
								if (dup2(p[1], 1) == -1) {
									edie("dup2()");
								}
								close(p[1]);
								fputs(input, stdout);
								exit(0);
						}
						_exit(0);
				}
				close(p[1]);
				if (dup2(p[0], 0) == -1) {
					edie("dup2()");
				}
				close(p[0]);
				waitpid(pid, NULL, 0);
			}

			struct rlimit rl;
			rl.rlim_cur = rl.rlim_max = lmem;
			if (setrlimit(RLIMIT_AS, &rl) == -1) {
				edie("setrlimit(RLIMIT_AS)");
			}
			rl.rlim_cur = rl.rlim_max = ltime;
			if (setrlimit(RLIMIT_CPU, &rl) == -1) {
				edie("setrlimit(RLIMIT_CPU)");
			}
			execvp(argv[0], argv);
			edie(argv[0]);
		}
	}

	sleep(ltime);

	kill(pid, SIGTERM);

	if (waitpid(pid, NULL, WNOHANG) == 0) {
		usleep(1000 * 1000 / 2);
		kill(pid, SIGKILL);
	}

	return 0;
}
