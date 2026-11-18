; .rx's declarations, for Zed's outline: the keyword is @context, the name @name. Sources and equations are listed at a
; module's top level and directly in a component's body, not inside its if/for/loading/errored regions.

(component_declaration
  "component" @context
  name: (_) @name
  parameters: (formal_parameters
    "(" @context
    ")" @context)) @item

(fn_declaration
  "fn" @context
  name: (_) @name
  parameters: (formal_parameters
    "(" @context
    ")" @context)) @item

(fn_signature
  (side)? @context
  (pure)? @context
  "fn" @context
  name: (_) @name
  parameters: (formal_parameters
    "(" @context
    ")" @context)) @item

(server_function_declaration
  (side) @context
  "fn" @context
  name: (_) @name
  parameters: (formal_parameters
    "(" @context
    ")" @context)) @item

(action_declaration
  "action" @context
  name: (_) @name
  parameters: (formal_parameters
    "(" @context
    ")" @context)) @item

(error_declaration
  "error" @context
  name: (_) @name) @item

(context_declaration
  "context" @context
  name: (_) @name) @item

(type_alias_declaration
  "type" @context
  name: (_) @name) @item

(interface_declaration
  "interface" @context
  name: (_) @name) @item

; Sources

(program
  (source_declaration
    "source" @context
    name: (_) @name) @item)

(program
  (export_statement
    declaration: (source_declaration
      "source" @context
      name: (_) @name) @item))

(component_declaration
  body: (view_block
    (source_declaration
      "source" @context
      name: (_) @name) @item))

; Equations (a destructuring one lists each name it binds)

(program
  (equation
    (deferred)? @context
    name: (identifier) @name) @item)

(program
  (export_statement
    declaration: (equation
      (deferred)? @context
      name: (identifier) @name) @item))

(component_declaration
  body: (view_block
    (equation
      (deferred)? @context
      name: (identifier) @name) @item))

(program
  (equation
    name: [
      (object_pattern
        [
          (shorthand_property_identifier_pattern) @name @item
          (object_assignment_pattern
            left: (shorthand_property_identifier_pattern) @name @item)
          (pair_pattern
            value: (identifier) @name @item)
          (rest_pattern
            (identifier) @name @item)
        ])
      (array_pattern
        [
          (identifier) @name @item
          (rest_pattern
            (identifier) @name @item)
        ])
    ]))

(component_declaration
  body: (view_block
    (equation
      name: [
        (object_pattern
          [
            (shorthand_property_identifier_pattern) @name @item
            (object_assignment_pattern
              left: (shorthand_property_identifier_pattern) @name @item)
            (pair_pattern
              value: (identifier) @name @item)
            (rest_pattern
              (identifier) @name @item)
          ])
        (array_pattern
          [
            (identifier) @name @item
            (rest_pattern
              (identifier) @name @item)
          ])
      ])))

(comment) @annotation
