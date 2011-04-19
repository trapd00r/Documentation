/*

...
8052
pthread_create: Resource temporarily unavailable
Aborted

*/

#include <semaphore.h>
#include <pthread.h>
#include <limits.h>
#include <stdio.h>
#include <stdlib.h>

#define DEFSTRUCT(d) typedef struct d d; struct d

DEFSTRUCT(mvar_int) {
	sem_t r, w;
	int v;
};

static void mvar_init(mvar_int *v) {
	sem_init(&v->r, 0, 0);
	sem_init(&v->w, 0, 1);
}

static void mvar_put(mvar_int *v, int x) {
	sem_wait(&v->w);
	v->v = x;
	sem_post(&v->r);
}

static int mvar_take(mvar_int *v) {
	int tmp;
	sem_wait(&v->r);
	tmp = v->v;
	sem_post(&v->w);
	return tmp;
}

DEFSTRUCT(context) {
	mvar_int *ctrl;
	mvar_int *out;
};

static pthread_attr_t attributes;

static void *work(void *ini) {
	mvar_int in;
	const context *c = ini;
	context t = { c->ctrl, &in };
	pthread_t dummy;
	mvar_init(&in);
	mvar_put(c->out, mvar_take(c->ctrl));
	if (pthread_create(&dummy, &attributes, work, &t)) {
		perror("pthread_create");
		abort();
	}
	for (;;) {
		mvar_put(c->out, mvar_take(&in));
	}
}

int main(void) {
	pthread_t dummy;
	mvar_int v, d;
	context t = { &d, &v };
	mvar_init(&v);
	mvar_init(&d);
	pthread_attr_init(&attributes);
	pthread_attr_setstacksize(&attributes, PTHREAD_STACK_MIN);
	pthread_attr_setdetachstate(&attributes, PTHREAD_CREATE_DETACHED);
	if (pthread_create(&dummy, &attributes, work, &t)) {
		perror("pthread_create");
		abort();
	}
	mvar_put(&d, 1);
	for (;;) {
		int n = mvar_take(&v);
		printf("%d\n", n);
		mvar_put(&d, n + 1);
	}
}
