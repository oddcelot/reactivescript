; Zed's tsx/indents.scm, without assignment expressions (the rx grammar has none). A braced body indents through the
; `{ … }` rule below: that covers .rx's `view_block` (component, if/else, for, loading, errored, portal bodies and
; fallbacks), `statement_block` (action, effect, server fn and handler bodies), `fn_body` and
; `jsx_expression`. JSX elements indent through their own rules, `<style>` through the `< … >` one.

[
  (call_expression)
  (member_expression)
  (lexical_declaration)
  (variable_declaration)
] @indent

; A declaration whose value runs onto the next line
[
  (source_declaration)
  (equation)
  (provide_declaration)
  (context_declaration)
  (write_statement)
  (guess_statement)
] @indent

; Indent a braceless body (`if (x)\n  y()`). When the body is a `{}` block the
; `@end` stops the range before the brace so the block rule handles it instead,
; which keeps Allman-style braces unindented.
(if_statement
  consequence: (statement_block)? @end) @indent

(else_clause
  (statement_block)? @end) @indent

(for_statement
  body: (statement_block)? @end) @indent

(for_in_statement
  body: (statement_block)? @end) @indent

(while_statement
  body: (statement_block)? @end) @indent

(_
  "["
  "]" @end) @indent

(_
  "<"
  ">" @end) @indent

(_
  "{"
  "}" @end) @indent

(_
  "("
  ")" @end) @indent

(jsx_opening_element
  ">" @end) @indent

(jsx_element
  (jsx_opening_element) @start
  (jsx_closing_element)? @end) @indent
