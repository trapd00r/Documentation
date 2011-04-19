":";exec sbcl --script $0

;2009-05-07
;last change 2009-05-07

#+sbcl
(declaim (sb-ext:muffle-conditions style-warning))

(load (merge-pathnames "public_html/pregexp/pregexp.lisp"
                       (user-homedir-pathname)))

(defun find-and-change-timestamp ()
  (multiple-value-bind (s min h d m y)
      (decode-universal-time
       (get-universal-time)
       ;use a bogus TZ arg, just to speed things up
       5)
    (declare (ignore s min h))
    (let (done)
      (loop
        (let ((curr-line (or (read-line nil nil) (return))))
          (when (and (not done)
                     (pregexp-match "[Ll]ast +([Cc]hange|[Mm]odified)"
                                    curr-line))
            (cond ((pregexp-match "\\d{8}" curr-line)
                   (setq curr-line
                         (pregexp-replace
                          "\\d{8}" curr-line
                          (format nil "~4,'0d~2,'0d~2,'0d"
                                  y m d))
                         done t))
                  ((pregexp-match "\\d{4}-\\d{2}-\\d{2}" curr-line)
                   (setq curr-line
                         (pregexp-replace
                          "\\d{4}-\\d{2}-\\d{2}" curr-line
                          (format nil "~4,'0d-~2,'0d-~2,'0d"
                                  y m d))
                         done t))))
          (princ curr-line)
          (terpri))))))

(find-and-change-timestamp)
