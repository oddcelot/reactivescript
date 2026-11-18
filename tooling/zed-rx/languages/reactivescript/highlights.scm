; ReactiveScript (.rx) for Zed. The TSX part is Zed's own tsx/highlights.scm, without what the rx grammar has no node
; for (assignment expressions and the assignment operators, `using`); the .rx part is at the end. A later pattern wins.
;
; Variables
(identifier) @variable

(call_expression
  function: (member_expression
    object: (identifier) @type
    (#any-of? @type
      "Promise" "Array" "Object" "Map" "Set" "WeakMap" "WeakSet" "Date" "Error" "TypeError"
      "RangeError" "SyntaxError" "ReferenceError" "EvalError" "URIError" "RegExp" "Function"
      "Number" "String" "Boolean" "Symbol" "BigInt" "Proxy" "ArrayBuffer" "DataView")))

; Properties
(property_identifier) @property

(shorthand_property_identifier) @property

(shorthand_property_identifier_pattern) @property

(private_property_identifier) @property

; Function and method calls
(call_expression
  function: (identifier) @function)

(call_expression
  function: (member_expression
    property: [
      (property_identifier)
      (private_property_identifier)
    ] @function.method))

(new_expression
  constructor: (identifier) @type.class)

(nested_type_identifier
  module: (identifier) @type)

; Function and method definitions
(function_expression
  name: (identifier) @function)

(function_declaration
  name: (identifier) @function)

(method_definition
  name: [
    (property_identifier)
    (private_property_identifier)
  ] @function.method)

(method_definition
  name: (property_identifier) @constructor
  (#eq? @constructor "constructor"))

(pair
  key: [
    (property_identifier)
    (private_property_identifier)
  ] @function.method
  value: [
    (function_expression)
    (arrow_function)
  ])

(variable_declarator
  name: (identifier) @function
  value: [
    (function_expression)
    (arrow_function)
  ])

; Parameters
(required_parameter
  (identifier) @variable.parameter)

(required_parameter
  (_
    ([
      (identifier)
      (shorthand_property_identifier_pattern)
    ]) @variable.parameter))

(required_parameter
  (_
    (object_assignment_pattern
      left: (shorthand_property_identifier_pattern) @variable.parameter)))

(required_parameter
  (_
    (assignment_pattern
      left: (identifier) @variable.parameter)))

(optional_parameter
  (_
    (object_assignment_pattern
      left: (shorthand_property_identifier_pattern) @variable.parameter)))

(optional_parameter
  (_
    (assignment_pattern
      left: (identifier) @variable.parameter)))

(optional_parameter
  (identifier) @variable.parameter)

(optional_parameter
  (_
    ([
      (identifier)
      (shorthand_property_identifier_pattern)
    ]) @variable.parameter))

(catch_clause
  parameter: (identifier) @variable.parameter)

(index_signature
  name: (identifier) @variable.parameter)

(arrow_function
  parameter: (identifier) @variable.parameter)

(type_predicate
  name: (identifier) @variable.parameter)

; Special identifiers
(type_annotation) @type

(type_identifier) @type

(predefined_type) @type.builtin

(type_alias_declaration
  (type_identifier) @type)

(type_alias_declaration
  value: (_
    (type_identifier) @type))

(interface_declaration
  (type_identifier) @type)

(class_declaration
  (type_identifier) @type.class)

(extends_clause
  value: (identifier) @type.class)

(extends_type_clause
  type: (type_identifier) @type)

(implements_clause
  (type_identifier) @type)

([
  (identifier)
  (shorthand_property_identifier)
  (shorthand_property_identifier_pattern)
] @constant
  (#match? @constant "^_*[A-Z_][A-Z\\d_]*$"))

; Literals
(this) @variable.special

(super) @variable.special

[
  (null)
  (undefined)
] @constant.builtin

[
  (true)
  (false)
] @boolean

(comment) @comment

[
  (string)
  (template_string)
  (template_literal_type)
] @string

(escape_sequence) @string.escape

(regex) @string.regex

(regex_flags) @keyword.operator.regex

(number) @number

; Tokens
[
  ";"
  "?."
  "."
  ","
  ":"
  "?"
] @punctuation.delimiter

[
  "-"
  "--"
  "+"
  "++"
  "*"
  "**"
  "/"
  "%"
  "<"
  "<="
  "<<"
  "="
  "=="
  "==="
  "!"
  "!="
  "!=="
  "=>"
  ">"
  ">="
  ">>"
  ">>>"
  "~"
  "^"
  "&"
  "|"
  "&&"
  "||"
  "??"
  "..."
] @operator

(regex
  "/" @string.regex)

[
  "("
  ")"
  "["
  "]"
  "{"
  "}"
] @punctuation.bracket

(ternary_expression
  [
    "?"
    ":"
  ] @operator)

; Keywords
[
  "abstract"
  "as"
  "async"
  "debugger"
  "declare"
  "default"
  "delete"
  "extends"
  "get"
  "implements"
  "in"
  "infer"
  "instanceof"
  "is"
  "keyof"
  "module"
  "namespace"
  "new"
  "of"
  "override"
  "private"
  "protected"
  "public"
  "readonly"
  "satisfies"
  "set"
  "static"
  "target"
  "typeof"
  "void"
  "with"
] @keyword

[
  "const"
  "let"
  "var"
  "function"
  "class"
  "enum"
  "interface"
  "type"
] @keyword.declaration

[
  "export"
  "from"
  "import"
] @keyword.import

[
  "await"
  "break"
  "case"
  "catch"
  "continue"
  "do"
  "else"
  "finally"
  "for"
  "if"
  "return"
  "switch"
  "throw"
  "try"
  "while"
  "yield"
] @keyword.control

(switch_default
  "default" @keyword.control)

(template_substitution
  "${" @punctuation.special
  "}" @punctuation.special) @embedded

(template_type
  "${" @punctuation.special
  "}" @punctuation.special) @embedded

(type_arguments
  "<" @punctuation.bracket
  ">" @punctuation.bracket)

(type_parameters
  "<" @punctuation.bracket
  ">" @punctuation.bracket)

(decorator
  "@" @punctuation.special)

(union_type
  "|" @punctuation.special)

(intersection_type
  "&" @punctuation.special)

(type_annotation
  ":" @punctuation.special)

(index_signature
  ":" @punctuation.special)

(type_predicate_annotation
  ":" @punctuation.special)

(public_field_definition
  "?" @punctuation.special)

(property_signature
  "?" @punctuation.special)

(method_signature
  "?" @punctuation.special)

(optional_parameter
  ([
    "?"
    ":"
  ]) @punctuation.special)

(jsx_opening_element
  [
    (identifier) @type @tag.component.jsx
    (member_expression
      object: (identifier) @type @tag.component.jsx
      property: (property_identifier) @type @tag.component.jsx)
    (member_expression
      object: (member_expression
        object: (identifier) @type @tag.component.jsx
        property: (property_identifier) @type @tag.component.jsx)
      property: (property_identifier) @type @tag.component.jsx)
    (member_expression
      object: (member_expression
        object: (member_expression
          object: (identifier) @type @tag.component.jsx
          property: (property_identifier) @type @tag.component.jsx)
        property: (property_identifier) @type @tag.component.jsx)
      property: (property_identifier) @type @tag.component.jsx)
  ])

(jsx_closing_element
  [
    (identifier) @type @tag.component.jsx
    (member_expression
      object: (identifier) @type @tag.component.jsx
      property: (property_identifier) @type @tag.component.jsx)
    (member_expression
      object: (member_expression
        object: (identifier) @type @tag.component.jsx
        property: (property_identifier) @type @tag.component.jsx)
      property: (property_identifier) @type @tag.component.jsx)
    (member_expression
      object: (member_expression
        object: (member_expression
          object: (identifier) @type @tag.component.jsx
          property: (property_identifier) @type @tag.component.jsx)
        property: (property_identifier) @type @tag.component.jsx)
      property: (property_identifier) @type @tag.component.jsx)
  ])

(jsx_self_closing_element
  [
    (identifier) @type @tag.component.jsx
    (member_expression
      object: (identifier) @type @tag.component.jsx
      property: (property_identifier) @type @tag.component.jsx)
    (member_expression
      object: (member_expression
        object: (identifier) @type @tag.component.jsx
        property: (property_identifier) @type @tag.component.jsx)
      property: (property_identifier) @type @tag.component.jsx)
    (member_expression
      object: (member_expression
        object: (member_expression
          object: (identifier) @type @tag.component.jsx
          property: (property_identifier) @type @tag.component.jsx)
        property: (property_identifier) @type @tag.component.jsx)
      property: (property_identifier) @type @tag.component.jsx)
  ])

(jsx_opening_element
  (identifier) @tag.jsx
  (#match? @tag.jsx "^[a-z][^.]*$"))

(jsx_closing_element
  (identifier) @tag.jsx
  (#match? @tag.jsx "^[a-z][^.]*$"))

(jsx_self_closing_element
  (identifier) @tag.jsx
  (#match? @tag.jsx "^[a-z][^.]*$"))

(jsx_attribute
  (property_identifier) @attribute.jsx)

(jsx_opening_element
  ([
    "<"
    ">"
  ]) @punctuation.bracket.jsx)

(jsx_closing_element
  ([
    "</"
    ">"
  ]) @punctuation.bracket.jsx)

(jsx_self_closing_element
  ([
    "<"
    "/>"
  ]) @punctuation.bracket.jsx)

(jsx_attribute
  "=" @punctuation.delimiter.jsx)

(jsx_text) @text.jsx

(html_character_reference) @string.special

; ---- ReactiveScript

; Keywords

[
  "source"
  "context"
  "key"
] @keyword.declaration

[
  "component"
  "action"
  "effect"
  "fn"
  "error"
] @keyword.declaration

[
  "provide"
  "use"
  "fails"
  "rejects"
  "instantiates"
  "latest"
  "peek"
  "pre"
  "pending?"
  "draft"
  "on"
  "to"
] @keyword

(deferred) @keyword.declaration
(side) @keyword
(pure) @keyword
(ref_modifier) @keyword

(context_declaration
  "source" @keyword)

[
  "guess"
  "refresh"
  "affects"
  "loading"
  "errored"
  "fallback"
  "portal"
] @keyword.control

(action_statement
  "action" @keyword.control)

(for_block
  "in" @keyword.control)

(await_expression
  "*" @keyword.control)

"->" @operator

; `:=` writes (and seeds a source): a keyword, so a write stands out from `=`
":=" @keyword.operator

; A source is state: its name, at its declaration and as the target of a write or a guess, is @variable.special.
; An equation is a value computed from others, never written: @constant.

(source_declaration
  name: (identifier) @variable.special)

(equation
  name: (identifier) @constant)

(equation
  name: (object_pattern
    [
      (shorthand_property_identifier_pattern) @constant
      (object_assignment_pattern
        left: (shorthand_property_identifier_pattern) @constant)
      (pair_pattern
        value: (identifier) @constant)
      (rest_pattern
        (identifier) @constant)
    ]))

(equation
  name: (array_pattern
    [
      (identifier) @constant
      (rest_pattern
        (identifier) @constant)
    ]))

(write_statement
  target: [
    (identifier) @variable.special
    (member_expression
      object: (identifier) @variable.special)
    (subscript_expression
      object: (identifier) @variable.special)
    (member_expression
      object: (subscript_expression
        object: (identifier) @variable.special))
  ])

(guess_statement
  target: [
    (identifier) @variable.special
    (member_expression
      object: (identifier) @variable.special)
    (subscript_expression
      object: (identifier) @variable.special)
    (member_expression
      object: (subscript_expression
        object: (identifier) @variable.special))
  ])

(key_clause
  name: (identifier) @property)

(context_declaration
  name: (identifier) @constant)

(provide_declaration
  name: (identifier) @constant)

(use_expression
  name: (identifier) @constant)

(pre_expression
  name: (identifier) @variable)

; Functions, actions, components, errors

(fn_declaration
  name: (identifier) @function)

(fn_signature
  name: (identifier) @function)

(server_function_declaration
  name: (identifier) @function)

(action_declaration
  name: (identifier) @function)

(component_declaration
  name: (identifier) @type)

(error_declaration
  name: (type_identifier) @type)

; Names bound by markup and catches

(for_block
  name: (identifier) @variable.parameter)

(errored_block
  parameter: (identifier) @variable.parameter)

(catch_expression
  parameter: (identifier) @variable.parameter)

(catch_expression
  "catch" @keyword.control)

; An effect's values, `$0` … `$n`

((identifier) @variable.special
  (#match? @variable.special "^\\$[0-9]+$"))

; The prelude's functions

(call_expression
  function: (identifier) @function.builtin
  (#any-of? @function.builtin "log" "onFlush" "onSettled"))

; <style>

(style_element
  (identifier) @tag.jsx)

(style_element
  [
    "<"
    ">"
    "</"
  ] @punctuation.bracket.jsx)
