; Override: color the argument of #pragma (e.g. "once", "pack(...)") as a
; preprocessor directive, matching the #pragma token itself.
(preproc_call
  directive: (preproc_directive) @_pragma
  argument: (preproc_arg) @keyword.directive
  (#eq? @_pragma "#pragma"))

; DEBUG
(preproc_directive) @keyword.directive