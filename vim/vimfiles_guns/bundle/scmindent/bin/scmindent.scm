":";exec mzscheme -r $0

;Dorai Sitaram
;Oct 8, 1999
;last change 2009-04-09

;This script takes lines of Scheme or Lisp code from its
;stdin and produces an indented version thereof on its
;stdout.

(define *lisp-keywords* '())

(define (set-lisp-indent-number sym num-of-subforms-to-be-indented-wide)
  (let* ((x (symbol->string sym))
         (c (assf (lambda (a) (string-ci=? x a)) *lisp-keywords*)))
    (unless c
      (set! c (cons x (box 0)))
      (set! *lisp-keywords* (cons c *lisp-keywords*)))
    (set-box! (cdr c) num-of-subforms-to-be-indented-wide)))

(for-each (lambda (s) (set-lisp-indent-number s 0))
          '(block
            handler-bind
            loop))

(for-each (lambda (s) (set-lisp-indent-number s 1))
          '(case
            defpackage dolist dotimes
            ecase etypecase eval-when
            flet
            labels lambda let let*
            prog1
            typecase
            unless unwind-protect
            when with-input-from-string with-open-file with-open-socket
            with-open-stream with-output-to-string))

(for-each (lambda (s) (set-lisp-indent-number s 2))
          '(defun destructuring-bind do do*
            if
            multiple-value-bind
            with-slots))

(let ((init-file (build-path (find-system-path 'home-dir) ".lispwords")))
  (when (file-exists? init-file)
    (call-with-input-file init-file
      (lambda (i)
        (let loop ()
          (let ((w (read i)))
            (unless (eof-object? w)
              (let ((n (car w)))
                (for-each (lambda (x) (set-lisp-indent-number x n))
                          (cdr w))))))))))

(define (past-next-token s i n)
  (let loop ((i i) (escape? #f))
    (if (>= i n) i
      (let ((c (string-ref s i)))
        (cond (escape? (loop (+ i 1) #f))
              ((char=? c #\\) (loop (+ i 1) #t))
              ((findf (lambda (c2)
                        (char=? c c2)) '(#\space #\tab #\( #\) #\[ #\] #\" #\' #\` #\, #\;))
               i)
              (else (loop (+ i 1) #f)))))))

(define (lisp-indent-number s)
  (let ((c (assf (lambda (a) (string-ci=? s a)) *lisp-keywords*)))
    (cond (c (unbox (cdr c)))
          ((regexp-match #rx"^(?i:def)" s) 0)
          (else -1))))

(define (literal-token? s)
  (let ((x (let ((i (open-input-string s)))
             (begin0 (read i) (close-input-port i)))))
    (or (char? x) (number? x) (string? x))))

(define (calc-subindent s i n)
  (let* ((j (past-next-token s i n))
         (num-aligned-subforms 0)
         (left-indent
           (if (= j i) 1
             (let ((w (substring s i j)))
               (if (and (>= i 2)
                        (let ((c-2 (string-ref s (- i 2))))
                          (memf (lambda (c) (char=? c c-2)) '(#\' #\`))))
                 1
                 (let ((nas (lisp-indent-number w)))
                   (cond ((>= nas 0) (set! num-aligned-subforms nas)
                                     2)
                         ((literal-token? w) 1)
                         ((= j n) 1)
                         (else (+ (- j i) 2)))))))))
    (values left-indent num-aligned-subforms j)))

(define (num-leading-spaces s)
  (let ((n (string-length s)))
    (let loop ((i 0))
      (if (>= i n) 0
        (case (string-ref s i)
          ((#\space) (loop (+ i 1)))
          ((#\tab) (loop (+ i 8)))
          (else i))))))

(define (string-trim-blanks s)
  (regexp-replace #rx"^[ \t]*(.*?)[ \t]*$" s "\\1"))

(define (indent-lines)
  (let ((left-i 0) (paren-stack '()) (stringp #f))
    (let loop ()
      (let ((curr-line (read-line)))
        (unless (eof-object? curr-line)
          (let* ((leading-spaces (num-leading-spaces curr-line))
                 (curr-left-i
                  (cond (stringp leading-spaces)
                        ((null? paren-stack)
                         (when (= left-i 0) (set! left-i leading-spaces))
                         left-i)
                        (else (let* ((lp (car paren-stack))
                                     (nas (vector-ref lp 1))
                                     (nfs (vector-ref lp 2))
                                     (extra-w 0))
                                (when (< nfs nas)
                                  (vector-set! lp 2 (+ nfs 1))
                                  (set! extra-w 2))
                                (+ (vector-ref lp 0) extra-w))))))
            (set! curr-line (string-trim-blanks curr-line))
            (do ((i 0 (+ i 1)))
                ((= i curr-left-i))
              (write-char #\space))
            (display curr-line) (newline)
            ;
            (let ((n (string-length curr-line))
                  (escapep #f)
                  (inter-word-space-p #f))
              (let loop ((i 0))
                (unless (>= i n)
                  (let ((c (string-ref curr-line i)))
                    (cond (escapep (set! escapep #f) (loop (+ i 1)))
                          ((char=? c #\\) (set! escapep #t))
                          (stringp
                           (when (char=? c #\") (set! stringp #f))
                           (loop (+ i 1)))
                          ((char=? c #\;) #t)
                          ((char=? c #\") (set! stringp #t)
                           (loop (+ i 1)))
                          ((or (char=? c #\space) (char=? c #\tab))
                           (unless inter-word-space-p
                             (set! inter-word-space-p #t)
                             (cond ((and paren-stack
                                         (car paren-stack)) =>
                                    (lambda (lp)
                                      (let ((nfs (vector-ref lp 2)))
                                        (vector-set! lp 2 (+ nfs 1)))))))
                           (loop (+ i 1)))
                          ((or (char=? c #\() (char=? c #\[))
                           (set! inter-word-space-p #f)
                           (let-values (((left-indent
                                          num-aligned-subforms
                                          j)
                                         (calc-subindent curr-line (+ i 1) n)))
                             (set! paren-stack
                                   (cons (vector (+ i curr-left-i left-indent)
                                                 num-aligned-subforms
                                                 0)
                                         paren-stack))
                             (loop  j)))
                          ((or (char=? c #\)) (char=? c #\]))
                           (set! inter-word-space-p #f)
                           (cond (paren-stack
                                  (set! paren-stack (cdr paren-stack)))
                                 (else (set! left-i 0)))
                           (loop (+ i 1)))
                          (else (set! inter-word-space-p #f)
                                (loop (+ i 1)))))))))
          (loop))))))

(indent-lines)

;eof
