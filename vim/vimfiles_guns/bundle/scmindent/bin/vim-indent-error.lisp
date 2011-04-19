(with-open-file (o "junk.html" :direction :output)
  (format o "<h1 style=\"font-family: sans-serif\" align=center>~
          Title</h1>~%~
          <h2 style=\"font-family: sans-serif\" align=center>Subtitle</h2>~%")
          (format o "<div align=center>~%<table cellpadding=2 width=\"80%\">~%")
          (format o "<tr style=\"font-weight: bold\">~%" *header-color*)
          (format o "<td align=right>Meeting Date:</td>~%")
          (more-code))
