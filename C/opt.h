#ifndef OPT_H_
#define OPT_H_

extern int opt_ind;
extern int opt_err;
extern const char *opt_arg;

int opt_get(int, char *const *, const char *);
void opt_reset(void);

#endif /* OPT_H_ */
