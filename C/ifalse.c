#include<stdio.h>
#include<stdlib.h>
#include<limits.h>
#include<ctype.h>
#define A(f,F)B f:z(!k.p->p)k.p->p->v F##=k.p->v; Z
#define B ; break; case
#define E "error message"
#define F(f,F)for(; ++n<l&&n[s]-f; F); if(n>=l)e,X
#define L(F,f)B F:z(!k.p->p)k.p->p->v=-(k.p->p->v f k.p->v); Z
#define X exit(EXIT_FAILURE);
#define Z return 0
#define e fputs(E"\n",stderr)
#define z(f)if(!k.p||f)e,X
#define W perror(E)
long typedef T; unsigned char typedef S; S*s; T V[UCHAR_MAX+1],n,l=1,i; FILE*F;
void typedef N; N*m(N*p,T n){ N*t=realloc(p,n); if(!t&&n)W,free(p),X Z?0:t; } N
C(N){ m(s,0); } N w(T k){ fwrite(&k,sizeof k,1,F); } T r(N){ if(fseek(F,-sizeof
i,SEEK_CUR))W,X if(fread(&i,sizeof i,1,F),fseek(F,-sizeof i,SEEK_CUR))W,X Z+i;
} struct q{ T v; struct q*p; } typedef Q; T d(Q*p){ Q k={ 0,p} ; for(; ++n<l; )
{ if(isdigit(n[s])){ S*b; if(k.v=strtol((char*)s+n,(char**)&b,10),n=b-s-1,d(&k)
)Z; } else if(islower(n[s])){ if(k.v=n[s],d(&k))Z; } else if(!isspace(n[s]))sw\
itch(n[s]){ default:e; X B'"':F('"',putchar(n[s]))B'{':F('}',)B'[':for(k.v=n,i=
1; i&&++n<l; )switch(n[s]){ case'[':++i B']':--i B'\'':++n B'"':F('"',)B'{':F(
'}',)} if(n>=l)e,X if(d(&k))Z B']':if((n=r())<0){ if(i=r(),!k.p)e,X k.p->v?w(i)
,w(n),w(i),n=-n:(n=r()); Z; } B'!':z(0)w(n); n=k.p->v; Z B'?':z(!k.p->p)k.p->p
->v?w(n),n=k.p->v:i; Z+1 B'#':z(!k.p->p)w(n); w(n=k.p->p->v); w(-k.p->v); Z+1 B
'\'':if(++n>=l)e,X if(k.v=n[s],d(&k))Z B'_':z(0)k.p->v=-k.p->v B'~':z(0)k.p->v=
~k.p->v B';':z(k.p->v<0|k.p->v>UCHAR_MAX)k.p->v=V[k.p->v]B':':z(!k.p->p)V[k.p
->v]=k.p->p->v; Z+1 A('+',+)A('-',-)A('*',*)A('/',/)L('=',==)L('>',>)A('&',&)A
('|',|)B'$':z(0)if(k.v=k.p->v,d(&k))Z B'%':Z B'\\':z(!k.p->p)i=k.p->v; k.p->v=
k.p->p->v; k.p->p->v=i B'@':z(!k.p->p||!k.p->p->p)i=k.p->p->p->v; k.p->p->p->v=
k.p->p->v; k.p->p->v=k.p->v; k.p->v=i B'.':z(0)printf("%ld",k.p->v); Z B',':z(0
)putchar(k.p->v); Z B'^':(k.v=getchar())-EOF||(k.v=-1); if(d(&k))Z B(S)'ß':case
'B':fflush(0)B(S)'ø':case'O':z(!k.p->p||k.p->v<0)p=k.p->p; for(; k.p->v--; p=p
->p)z(!p)k.p->v=p->v; } } exit(0); } int main(int c,char**i){ FILE*f=stdin; if(
c>1&&(*1[i]-'-'||1[1[i]])&&!(f=fopen(1[i],"r")))perror(1[i]),X if(!(F=tmpfile()
))W,X for(0[s=m(s,n=9)]=' '; (c=getc(f))-EOF; ++l)l[l>n-2?s=m(s,n*=2):s]=c; if(
l[s]=0,atexit(C))e,C(),X n=-1; d(0); e; X}
