; Embedded languages in ReactiveScript (.rx) for Zed.
;
; Based on the rx grammar's own queries/injections.scm and tree-sitter-javascript's injections.scm (both MIT).

; A <style> element's body is CSS
((style_element
  (raw_text) @injection.content)
  (#set! injection.language "css"))

; JSDoc in /** */ comments only: a // line or a plain /* */ block is prose
((comment) @injection.content
  (#match? @injection.content "^/\\*\\*[^*/]")
  (#set! injection.language "jsdoc"))

; Regex syntax in regex literals
((regex_pattern) @injection.content
  (#set! injection.language "regex"))

; Tagged templates, where the tag names the language: css`…`, html`…`, sql`…`, graphql`…`. The template's text pieces
; are parsed together as one document; the `${…}` holes between them stay rx.
(call_expression
  function: [
    (identifier) @injection.language
    (member_expression
      property: (property_identifier) @injection.language)
  ]
  arguments: (template_string
    (string_fragment) @injection.content)
  (#any-of? @injection.language "css" "html" "sql" "graphql")
  (#set! injection.combined))

; gql`…` is GraphQL
(call_expression
  function: (identifier) @_tag
  arguments: (template_string
    (string_fragment) @injection.content)
  (#eq? @_tag "gql")
  (#set! injection.language "graphql")
  (#set! injection.combined))

; styled.div`…`, styled(Button)`…`: CSS
(call_expression
  function: [
    (member_expression
      object: (identifier) @_styled)
    (call_expression
      function: (identifier) @_styled)
  ]
  arguments: (template_string
    (string_fragment) @injection.content)
  (#eq? @_styled "styled")
  (#set! injection.language "css")
  (#set! injection.combined))
