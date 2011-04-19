#include <stdio.h>
#include <stdlib.h>
#include <ctype.h>
#include <string.h>

enum {
	QualNone = 0,
	QualConst = 1,
	QualVolatile = 2
};

typedef enum {
	StorNone,
	StorAuto,
	StorStatic,
	StorExtern,
	StorRegister,
	StorTypedef
} StorageClass;

typedef enum {
	ExprId,
	ExprPtr,
	ExprArray,
	ExprFunc
} ExprType;

typedef struct Expr Expr;
typedef struct Decl Decl;
typedef struct DeclList DeclList;

struct Expr {
	ExprType type;
	Expr *next;
	union {
		const char *id;
		int ptrquali;
		unsigned long nelem;
		DeclList *args;
	} u;
};

typedef enum {
	TyNone,
	TyVoid,
	TyUChar,
	TySChar,
	TyChar,
	TyUShort,
	TyShort,
	TyUInt,
	TyInt,
	TyULong,
	TyLong,
	TyFloat,
	TyDouble,
	TyUser,
	TyUserStruct,
	TyUserUnion,
	TyUserEnum
} TypeType;

struct Decl {
	StorageClass storage;
	TypeType type;
	const char *ext;
	int quali;
	Expr *expr;
};

struct DeclList {
	Decl *d;
	DeclList *next;
};

#ifdef __GNUC__
__attribute__((__noreturn__))
#endif
static void wtf(const char *s) {
	fprintf(stderr, "internal error: %s\n", s);
	abort();
}

static const char *strclass(StorageClass sc) {
	switch (sc) {
		case StorNone:
			return "";
		case StorAuto:
			return "auto";
		case StorStatic:
			return "static";
		case StorExtern:
			return "extern";
		case StorRegister:
			return "register";
		case StorTypedef:
			return "typedef";
	}
	wtf("unknown storage class");
}

static const char *rstrclass(StorageClass sc) {
	switch (sc) {
		case StorNone:
			return "";
		case StorAuto:
			return "automatic ";
		case StorStatic:
			return "static ";
		case StorExtern:
			return "external ";
		case StorRegister:
			return "register ";
		case StorTypedef:
			return "alias for ";
	}
	wtf("unknown storage class");
}

static void print_decl_list(const DeclList *);

static int idchar(char c) {
	return c == '_' || isalnum((unsigned char)c);
}

static int idstart(char c) {
	return idchar(c) && !isdigit((unsigned char)c);
}

static void print_word(const char *p) {
	for (; idchar(*p); ++p) {
		putchar(*p);
	}
}

static int cmp_word(const char *ss, const char *tt) {
	const unsigned char *s = (const unsigned char *)ss;
	const unsigned char *t = (const unsigned char *)tt;
	for (; idchar(*s) && idchar(*t); ++s, ++t) {
		if (*s < *t) {
			return -1;
		}
		if (*s > *t) {
			return 1;
		}
	}
	return idchar(*s) ? -1 : idchar(*t) ? 1 : 0 ;
}

static int is_keyword(const char *s) {
	switch (*s++) {
		case 'a':
			return cmp_word(s, "uto") == 0;
		case 'b':
			return cmp_word(s, "reak") == 0;
		case 'c':
			switch (*s++) {
				case 'a':
					return cmp_word(s, "se") == 0;
				case 'h':
					return cmp_word(s, "ar") == 0;
				case 'o':
					return cmp_word(s, "nst") == 0;
			}
			break;
		case 'd':
			switch (*s++) {
				case 'e':
					return cmp_word(s, "fault") == 0;
				case 'o':
					switch (*s++) {
						case 'u':
							return cmp_word(s, "ble") == 0;
						default:
							return idchar(s[-1]) == 0;
					}
					break;
			}
			break;
		case 'e':
			switch (*s++) {
				case 'l':
					return cmp_word(s, "se") == 0;
				case 'n':
					return cmp_word(s, "um") == 0;
				case 'x':
					return cmp_word(s, "tern") == 0;
			}
			break;
		case 'f':
			switch (*s++) {
				case 'l':
					return cmp_word(s, "oat") == 0;
				case 'o':
					return cmp_word(s, "r") == 0;
			}
			break;
		case 'g':
			return cmp_word(s, "oto") == 0;
		case 'i':
			switch (*s++) {
				case 'f':
					return idchar(*s) == 0;
				case 'n':
					return cmp_word(s, "t") == 0;
			}
			break;
		case 'l':
			return cmp_word(s, "ong") == 0;
		case 'r':
			switch (*s++) {
				case 'e':
					switch (*s++) {
						case 'g':
							return cmp_word(s, "ister") == 0;
						case 't':
							return cmp_word(s, "urn") == 0;
					}
					break;
			}
			break;
		case 's':
			switch (*s++) {
				case 'h':
					return cmp_word(s, "ort") == 0;
				case 'i':
					switch (*s++) {
						case 'g':
							return cmp_word(s, "ned") == 0;
						case 'z':
							return cmp_word(s, "eof") == 0;
					}
					break;
				case 't':
					switch (*s++) {
						case 'a':
							return cmp_word(s, "tic") == 0;
						case 'r':
							return cmp_word(s, "ruct") == 0;
						case 'w':
							return cmp_word(s, "itch") == 0;
					}
					break;
			}
			break;
		case 't':
			return cmp_word(s, "ypedef") == 0;
		case 'u':
			switch (*s++) {
				case 'n':
					switch (*s++) {
						case 'i':
							return cmp_word(s, "on") == 0;
						case 's':
							return cmp_word(s, "igned") == 0;
					}
					break;
			}
			break;
		case 'v':
			switch (*s++) {
				case 'o':
					switch (*s++) {
						case 'i':
							return cmp_word(s, "d") == 0;
						case 'l':
							return cmp_word(s, "atile") == 0;
					}
					break;
			}
			break;
		case 'w':
			return cmp_word(s, "hile") == 0;
	}
	return 0;
}

static void print_expr(const Expr *e, StorageClass sc) {
	switch (e->type) {

		case ExprId:
			if (e->u.id) {
				print_word(e->u.id);
				printf(": %s", rstrclass(sc));
			}
			return;

		case ExprPtr:
			print_expr(e->next, sc);
			printf(
				"%s%spointer to ",
				e->u.ptrquali & QualConst ? "const " : "",
				e->u.ptrquali & QualVolatile ? "volatile " : ""
			);
			return;

		case ExprArray:
			print_expr(e->next, sc);
			printf("array[%lu] of ", e->u.nelem);
			return;

		case ExprFunc:
			print_expr(e->next, sc);
			fputs("function(", stdout);
			print_decl_list(e->u.args);
			fputs(") returning ", stdout);
			return;
	}
	wtf("unknown expression type");
}

static void print_type(TypeType t, const char *e) {
	switch (t) {
		case TyNone:
			wtf("missing type");
		case TyVoid:
			fputs("void", stdout);
			return;
		case TyUChar:
			fputs("unsigned char", stdout);
			return;
		case TySChar:
			fputs("signed char", stdout);
			return;
		case TyChar:
			fputs("char", stdout);
			return;
		case TyUShort:
			fputs("unsigned short", stdout);
			return;
		case TyShort:
			fputs("short", stdout);
			return;
		case TyUInt:
			fputs("unsigned int", stdout);
			return;
		case TyInt:
			fputs("int", stdout);
			return;
		case TyULong:
			fputs("unsigned long", stdout);
			return;
		case TyLong:
			fputs("long", stdout);
			return;
		case TyFloat:
			fputs("float", stdout);
			return;
		case TyDouble:
			fputs("double", stdout);
			return;
		case TyUser:
			print_word(e);
			return;
		case TyUserStruct:
			fputs("struct ", stdout);
			print_word(e);
			return;
		case TyUserUnion:
			fputs("union ", stdout);
			print_word(e);
			return;
		case TyUserEnum:
			fputs("enum ", stdout);
			print_word(e);
			return;
	}
	wtf("unknown type");
}

static void print_decl(const Decl *d) {
	print_expr(d->expr, d->storage);
	if (d->quali & QualConst) {
		fputs("const ", stdout);
	}
	if (d->quali & QualVolatile) {
		fputs("volatile ", stdout);
	}
	print_type(d->type, d->ext);
}

static void print_decl_list(const DeclList *dl) {
	if (!dl) {
		return;
	}
	print_decl_list(dl->next);
	if (dl->next) {
		fputs(", ", stdout);
	}
	print_decl(dl->d);
}


#define COUNTOF(a) (sizeof (a) / sizeof *(a))

#define MKNAME(a, b) a ## b
#define ALLOC(T) MKNAME(Alloc_, T)
#define MGET(T) MKNAME(alloc_get_, T)
#define MRESET(T) MKNAME(alloc_reset_, T)
#define MINIT(p, n) { p, 0, n }
#define DEFINE_ALLOC(T) \
	typedef struct { \
		T *store; \
		size_t len, size; \
	} ALLOC(T); \
	static T *MGET(T)(ALLOC(T) *a) { \
		return a->len < a->size ? &a->store[a->len++] : NULL; \
	} \
	static void MRESET(T)(ALLOC(T) *a) { \
		a->len = 0; \
	} \
	extern int you_dont_see_this

DEFINE_ALLOC(Decl);
DEFINE_ALLOC(Expr);
DEFINE_ALLOC(DeclList);

typedef struct AlloCon {
	ALLOC(Decl) *dx;
	ALLOC(Expr) *ex;
	ALLOC(DeclList) *lx;
} AlloCon;

static void skipws(char **s) {
	while (isspace((unsigned char)**s)) {
		++*s;
	}
}

static int skipword(char **s, const char *w) {
	size_t len = strlen(w);
	if (
		strncmp(*s, w, len) == 0 &&
		!idchar((*s)[len])
	) {
		*s += len;
		return 1;
	}
	return 0;
}

static char *skipanyword(char **s) {
	char *t = *s;
	if (!idstart(**s)) {
		return NULL;
	}
	do {
		++*s;
	} while (idchar(**s));
	if (is_keyword(t)) {
		return NULL;
	}
	return t;
}

static void type_conflict(TypeType t1, const char *e1, TypeType t2, const char *e2) {
	fputs("conflicting types: ", stdout);
	print_type(t1, e1);
	fputs(", ", stdout);
	print_type(t2, e2);
	fputs("\n", stdout);
}

#define MEMCHECK(x) \
	if (!(x)) { \
		fputs("Out of memory\n", stdout); \
		return NULL; \
	} else ((void)0)

#define STORCHECK(d, s) do { \
	if ((d)->storage == StorNone) { \
		(d)->storage = (s); \
	} else { \
		printf("conflicting storage classes: %s, %s\n", strclass((d)->storage), strclass(s)); \
		return NULL; \
	} \
} while (0)

#define TYPECHECK(d, t) do { \
	if ((d)->type == TyNone) { \
		(d)->type = (t); \
	} else { \
		type_conflict((d)->type, (d)->ext, t, NULL); \
		return NULL; \
	} \
} while (0)

static Decl *parse_decl_r(char **, AlloCon);

static int argconv(Expr *e, AlloCon con) {
	if (!e) {
		wtf("malformed expression (early null)");
	}
	switch (e->type) {

		case ExprId:
			return 0;

		case ExprPtr:
			return argconv(e->next, con);

		case ExprArray:
			if (e->next->type == ExprId) {
				e->type = ExprPtr;
				e->u.ptrquali = QualNone;
				return 0;
			}
			return argconv(e->next, con);

		case ExprFunc:
			if (e->next->type == ExprId) {
				Expr *p;
				if (!(p = MGET(Expr)(con.ex))) {
					fputs("Out of memory\n", stdout);
					return -1;
				}
				p->type = ExprPtr;
				p->u.ptrquali = QualNone;
				p->next = e->next;
				e->next = p;
				return 0;
			}
			return argconv(e->next, con);
	}
	wtf("malformed expression (unknown node type)");
}

static Expr *parse_expr(char **s, AlloCon con) {
	Expr *e;

	skipws(s);
	if (**s == '*') {
		++*s;
		MEMCHECK(e = MGET(Expr)(con.ex));
		e->type = ExprPtr;
		e->u.ptrquali = QualNone;
		for (;;) {
			skipws(s);
			if (skipword(s, "const")) {
				if (e->u.ptrquali & QualConst) {
					fputs("warning: duplicate const\n", stdout);
				} else {
					e->u.ptrquali |= QualConst;
				}
			} else if (skipword(s, "volatile")) {
				if (e->u.ptrquali & QualVolatile) {
					fputs("warning: duplicate volatile\n", stdout);
				} else {
					e->u.ptrquali |= QualVolatile;
				}
			} else {
				break;
			}
		}
		if (!(e->next = parse_expr(s, con))) {
			return NULL;
		}
		return e;
	}

	e = NULL;
	if (**s == '(') {
		char *t = *s;
		++*s;
		skipws(s);
		if (**s != ')' && (e = parse_expr(s, con)) && (skipws(s), **s == ')')) {
			++*s;
			skipws(s);
		} else {
			e = NULL;
			*s = t;
		}
	}
	if (!e) {
		MEMCHECK(e = MGET(Expr)(con.ex));
		e->type = ExprId;
		e->next = NULL;
		e->u.id = skipanyword(s);
		skipws(s);
	}

	if (**s == '[') {
		do {
			Expr *f;
			++*s;
			skipws(s);
			MEMCHECK(f = MGET(Expr)(con.ex));
			f->type = ExprArray;
			if (e->type == ExprFunc) {
				fputs("functions can't return arrays\n", stdout);
				return NULL;
			}
			f->next = e;
			f->u.nelem = strtoul(*s, s, 0);
			skipws(s);
			if (**s != ']') {
				fputs("missing ']'\n", stdout);
				return NULL;
			}
			++*s;
			e = f;
			skipws(s);
		} while (**s == '[');
		return e;
	}
	if (**s == '(') {
		Expr *f;
		++*s;
		MEMCHECK(f = MGET(Expr)(con.ex));
		f->type = ExprFunc;
		if (e->type == ExprArray) {
			fputs("arrays can't store functions\n", stdout);
			return NULL;
		}
		if (e->type == ExprFunc) {
			fputs("functions can't return functions\n", stdout);
			return NULL;
		}
		f->next = e;
		f->u.args = NULL;
		skipws(s);
		if (**s != ')') {
			do {
				DeclList *l;
				MEMCHECK(l = MGET(DeclList)(con.lx));
				if (!(l->d = parse_decl_r(s, con))) {
					return NULL;
				}
				if (argconv(l->d->expr, con)) {
					return NULL;
				}

				if (
					(
						l->d->type == TyVoid &&
						l->d->expr->type == ExprId &&
						f->u.args
					) ||
					(
						f->u.args &&
						f->u.args->d->type == TyVoid &&
						f->u.args->d->expr->type == ExprId
					)
				) {
					fputs("invalid void parameter\n", stdout);
					return NULL;
				}

				l->next = f->u.args;
				f->u.args = l;
				skipws(s);
			} while (**s == ',' && (++*s, 1));
			if (**s != ')') {
				fputs("missing ')'\n", stdout);
				return NULL;
			}
		}
		++*s;
		e = f;
		return e;
	}
	return e;
}

static Decl *parse_decl_r(char **s, AlloCon con) {
	Decl *d;
	enum { DefSigned, Signed, Unsigned } sign = DefSigned;
	enum { DefSize, Short, Long } size = DefSize;

	MEMCHECK(d = MGET(Decl)(con.dx));
	d->storage = StorNone;
	d->type = TyNone;
	d->ext = NULL;
	d->quali = QualNone;
	d->expr = NULL;

	for (;;) {
		skipws(s);
		if (skipword(s, "auto")) {
			STORCHECK(d, StorAuto);
		} else if (skipword(s, "static")) {
			STORCHECK(d, StorStatic);
		} else if (skipword(s, "extern")) {
			STORCHECK(d, StorExtern);
		} else if (skipword(s, "register")) {
			STORCHECK(d, StorRegister);
		} else if (skipword(s, "typedef")) {
			STORCHECK(d, StorTypedef);
		} else if (skipword(s, "const")) {
			if (d->quali & QualConst) {
				fputs("warning: duplicate const\n", stdout);
			} else {
				d->quali |= QualConst;
			}
		} else if (skipword(s, "volatile")) {
			if (d->quali & QualVolatile) {
				fputs("warning: duplicate volatile\n", stdout);
			} else {
				d->quali |= QualVolatile;
			}
		} else if (skipword(s, "signed")) {
			switch (sign) {
				case DefSigned:
					sign = Signed;
					break;
				case Signed:
					fputs("warning: duplicate signed\n", stdout);
					break;
				case Unsigned:
					fputs("conflicting sign specifiers: unsigned, signed\n", stdout);
					return NULL;
			}
		} else if (skipword(s, "unsigned")) {
			switch (sign) {
				case DefSigned:
					sign = Unsigned;
					break;
				case Unsigned:
					fputs("warning: duplicate unsigned\n", stdout);
					break;
				case Signed:
					fputs("conflicting sign specifiers: signed, unsigned\n", stdout);
					return NULL;
			}
		} else if (skipword(s, "short")) {
			switch (size) {
				case DefSize:
					size = Short;
					break;
				case Short:
					fputs("duplicate short\n", stdout);
					return NULL;
				case Long:
					fputs("conflicting size specifiers: long, short\n", stdout);
					return NULL;
			}
		} else if (skipword(s, "long")) {
			switch (size) {
				case DefSize:
					size = Long;
					break;
				case Long:
					fputs("duplicate unsigned\n", stdout);
					break;
				case Short:
					fputs("conflicting size specifiers: short, long\n", stdout);
					return NULL;
			}
		} else if (skipword(s, "void")) {
			TYPECHECK(d, TyVoid);
		} else if (skipword(s, "int")) {
			TYPECHECK(d, TyInt);
		} else if (skipword(s, "float")) {
			TYPECHECK(d, TyFloat);
		} else if (skipword(s, "double")) {
			TYPECHECK(d, TyDouble);
		} else if (skipword(s, "struct")) {
			char *o;
			skipws(s);
			if (!(o = skipanyword(s))) {
				fputs("missing struct tag\n", stdout);
				return NULL;
			}
			if (d->type != TyNone) {
				type_conflict(d->type, d->ext, TyUserStruct, o);
				return NULL;
			}
			d->type = TyUserStruct;
			d->ext = o;
		} else if (skipword(s, "union")) {
			char *o;
			skipws(s);
			if (!(o = skipanyword(s))) {
				fputs("missing union tag\n", stdout);
				return NULL;
			}
			if (d->type != TyNone) {
				type_conflict(d->type, d->ext, TyUserUnion, o);
				return NULL;
			}
			d->type = TyUserUnion;
			d->ext = o;
		} else if (skipword(s, "enum")) {
			char *o;
			skipws(s);
			if (!(o = skipanyword(s))) {
				fputs("missing enum tag\n", stdout);
				return NULL;
			}
			if (d->type != TyNone) {
				type_conflict(d->type, d->ext, TyUserEnum, o);
				return NULL;
			}
			d->type = TyUserEnum;
			d->ext = o;
		} else if (
			d->type == TyNone &&
			sign == DefSigned &&
			size == DefSize &&
			(d->ext = skipanyword(s))
		) {
			d->type = TyUser;
		} else {
			break;
		}
	}

	if (size == Short) {
		switch (d->type) {
			case TyNone:
			case TyInt:
				d->type = TyShort;
				break;
			default:
				fputs("'short' invalid for ", stdout);
				print_type(d->type, d->ext);
				fputs("\n", stdout);
				return NULL;
		}
	} else if (size == Long) {
		switch (d->type) {
			case TyNone:
			case TyInt:
				d->type = TyLong;
				break;
			default:
				fputs("'long' invalid for ", stdout);
				print_type(d->type, d->ext);
				fputs("\n", stdout);
				return NULL;
		}
	}

	if (sign == Signed) {
		switch (d->type) {
			case TyNone:
				d->type = TyInt;
				break;
			case TyChar:
				d->type = TySChar;
				break;
			case TyShort:
			case TyInt:
			case TyLong:
				break;
			default:
				fputs("'signed' invalid for ", stdout);
				print_type(d->type, d->ext);
				fputs("\n", stdout);
				return NULL;
		}
	} else if (sign == Unsigned) {
		switch (d->type) {
			case TyNone:
				d->type = TyUInt;
				break;
			case TyChar:
				d->type = TyUChar;
				break;
			case TyShort:
				d->type = TyUShort;
				break;
			case TyInt:
				d->type = TyUInt;
				break;
			case TyLong:
				d->type = TyULong;
				break;
			default:
				fputs("'unsigned' invalid for ", stdout);
				print_type(d->type, d->ext);
				fputs("\n", stdout);
				return NULL;
		}
	}

	if (d->type == TyNone) {
		fputs("missing type\n", stdout);
		return NULL;
	}

	if (!(d->expr = parse_expr(s, con))) {
		return NULL;
	}

	if (d->type == TyVoid) {
		switch (d->expr->type) {

			case ExprId:
				if (d->expr->u.id) {
					fputs("invalid void variable\n", stdout);
					return NULL;
				}
				break;

			case ExprArray:
				fputs("invalid void array\n", stdout);
				return NULL;

			case ExprPtr:
			case ExprFunc:
				break;
		}
	}

	return d;
}

static Decl *parse_decl(char *s, AlloCon con) {
	Decl *d = parse_decl_r(&s, con);
	if (!d) {
		return NULL;
	}
	while (*s == ';' || *s == '\n') {
		++s;
	}
	if (*s) {
		fputs("trailing garbage\n", stdout);
		return NULL;
	}
	return d;
}

int main(void) {
	enum {MAXLINE = 512};

	char buf[MAXLINE];
	Decl db[MAXLINE / 2];
	Expr eb[MAXLINE];
	DeclList lb[MAXLINE / 2];

	ALLOC(Decl) ad = MINIT(db, COUNTOF(db));
	ALLOC(Expr) ae = MINIT(eb, COUNTOF(eb));
	ALLOC(DeclList) al = MINIT(lb, COUNTOF(lb));
	AlloCon con = { &ad, &ae, &al };

	while (fgets(buf, sizeof buf, stdin)) {
		Decl *d;
		MRESET(Decl)(con.dx);
		MRESET(Expr)(con.ex);
		MRESET(DeclList)(con.lx);
		if ((d = parse_decl(buf, con))) {
			print_decl(d);
			putchar('\n');
		}
	}
	return 0;
}
