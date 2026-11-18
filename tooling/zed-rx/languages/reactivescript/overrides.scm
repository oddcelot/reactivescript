; Zed's tsx/overrides.scm: the scopes config.toml's [overrides.*] name. Markup in a `view_block` is not an `element`
; scope: `//` comments are valid there, as in a block.
(comment) @comment.inclusive

(string) @string

(template_string
  (string_fragment) @string)

(jsx_element) @element

(return_statement
  (parenthesized_expression) @element)

(arrow_function
  body: (parenthesized_expression) @element)

[
  (jsx_opening_element)
  (jsx_closing_element)
  (jsx_self_closing_element)
  (jsx_expression)
] @default

(_
  value: (call_expression
    function: (identifier) @function_name_before_type_arguments
    type_arguments: (type_arguments)))
