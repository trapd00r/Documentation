":";exec mzscheme -r $0 "$@" 

;Dorai Sitaram
;Oct 8, 1999

;This script takes lines of Scheme or Lisp code from its
;stdin and produces an indented version thereof on its
;stdout.

(define *define-style-tokens*
  (map symbol->string
       '(
         define
         define-syntax
         case
         fluid-let
         lambda
         let
         let*
         letrec
         unless
         when
         )))

(define add-define-style-tokens
  (lambda (s)
    (for-each
      (lambda (x)
        (set! *define-style-tokens*
          (cons (symbol->string x) *define-style-tokens*)))
      s)))

(define *scheme-words-file* "~/.schemewords")

(if (file-exists? *scheme-words-file*)
    (call-with-input-file *scheme-words-file*
      (lambda (i)
        (add-define-style-tokens (read i)))))

(define define-style-token?
  (lambda (s)
    (let loop ((tt *define-style-tokens*))
      (cond ((null? tt) #f)
            ((string-ci=? (car tt) s) #t)
            (else (loop (cdr tt)))))))

(define past-next-token
  (lambda (s i n)
    (let loop ((j i))
      (if (>= j n) j
          (let ((c (string-ref s j)))
            (if (or (char-whitespace? c)
                    (memv c '(#\( #\) #\' #\` #\, #\;))) j
                (loop (+ j 1))))))))

(define calc-subindent
  (lambda (s i n)
    (let ((j (past-next-token s i n)))
      (cond ((= j i) 1)
            ((define-style-token? (substring s i j)) 2)
            ((= j n) 1)
            (else (+ (- j i) 2))))))

(define write-spaces
  (lambda (n)
    (let loop ((i 0))
      (if (< i n)
          (begin
            (write-char #\space)
            (loop (+ i 1)))))))

(define num-leading-spaces
  (lambda (s)
    (let ((n (string-length s)))
      (let loop ((i 0))
        (if (>= i n) #f
            (let ((c (string-ref s i)))
              (case c
                ((#\space) (loop (+ i 1)))
                ((#\tab) (loop (+ i 8)))
                (else i))))))))

(define string-trim-blanks
  (lambda (s)
    (let ((orig-n (string-length s)))
      (let ((i 0) (n orig-n))
        (let loop ((k i))
          (if (or (>= k n)
                  (not (char-whitespace? (string-ref s k))))
              (set! i k)
              (loop (+ k 1))))
        (let loop ((k (- n 1)))
          (if (or (<= k i)
                  (not (char-whitespace? (string-ref s k))))
              (set! n (+ k 1))
              (loop (- k 1))))
        (cond ((and (= i 0) (= n orig-n)) s)
              ((= i n) " ")
              (else (substring s i n)))))))

(define indent-lines
  (lambda ()
    (let loop ((left-i 0) (paren-stack '()) (verb? #f))
      (let ((curr-line (read-line)))
        ;(printf "left-i = ~a; paren-stack = ~a~n" left-i paren-stack)
        ;(printf "~a~n" curr-line)
        (if (not (eof-object? curr-line))
            (let* ((leading-spaces (num-leading-spaces curr-line))
                   (curr-left-i
                     (cond (verb? leading-spaces)
                           ((null? paren-stack)
                            (if (and (= left-i 0) leading-spaces)
                                (set! left-i leading-spaces))
                            left-i)
                           (else (+ (caar paren-stack)
                                    (cdar paren-stack)))))
                   (s (string-trim-blanks curr-line))
                   (n (string-length s)))
              (write-spaces curr-left-i)
              (display s) (newline)
              ;
              (let loop2 ((i 0) (j curr-left-i) (paren-stack paren-stack)
                                (verb? verb?) (esc? #f))
                (if (>= i n)
                    (loop left-i paren-stack
                          (if (eqv? verb? 'comment) #f verb?))
                    (let ((c (string-ref s i)))
                      (cond ((eqv? verb? 'comment)
                             (loop2 (+ i 1) (+ j 1) paren-stack 'comment #f))
                            (esc? (loop2 (+ i 1) (+ j 1)
                                         paren-stack verb? #f))
                            ((char=? c #\\)
                             (loop2 (+ i 1) (+ j 1) paren-stack verb? #t))
                            ((eqv? verb? 'string)
                             (loop2 (+ i 1) (+ j 1) paren-stack
                                    (if (char=? c #\") #f 'string) #f))
                            ((char=? c #\;)
                             (loop2 (+ i 1) (+ j 1) paren-stack 'comment #f))
                            ((char=? c #\")
                             (loop2 (+ i 1) (+ j 1) paren-stack 'string #f))
                            ((char=? c #\() ;)
                             (loop2 (+ i 1) (+ j 1)
                                    (cons (cons j (calc-subindent
                                                    s (+ i 1) n))
                                          paren-stack)
                                    #f #f))
                            ;(
                            ((char=? c #\))
                              (loop2 (+ i 1) (+ j 1)
                                     (if (pair? paren-stack) (cdr paren-stack)
                                         (begin (set! left-i 0) '()))
                                     #f #f))
                            (else (loop2 (+ i 1) (+ j 1)
                                         paren-stack #f #f))))))))))))

(indent-lines)

;eof
