// shortHover on TypeScript's hover markdown, as volar-service-typescript writes it.   node test/hover.js
const assert = require("node:assert");
const { shortHover } = require("../src/index.js");

const fence = s => "```typescript\n" + s + "\n```";
// the service's layout: the type, the documentation (empty or not), then the tags, each line ending in a hard break
const hover = (type, doc, ...tags) => [fence(type), ...(tags.length ? [doc, tags.join("  \n\n")] : doc ? [doc] : [])].join("\n\n");
const url = u => `*@url* — ${u}`;
const mdn = "https://developer.mozilla.org/en-US/docs/Web";

const cases = [
  ["an HTML tag: its name, its element's interface, the reference",
    hover("(property) JSX.HTMLElementTags.p: JSX.HTMLAttributes<HTMLParagraphElement> & JSX.Properties<HTMLParagraphElement>", "", url(`${mdn}/HTML/Element/p`), url(`${mdn}/API/HTMLParagraphElement`)),
    `\`<p>\` · [\`HTMLParagraphElement\`](${mdn}/API/HTMLParagraphElement)\n\n[MDN Reference](${mdn}/HTML/Element/p)`],
  ["a tag whose name is quoted, without links",
    hover('(property) JSX.SVGElementTags."font-face": JSX.SVGAttributes<SVGElement>', ""),
    "`<font-face>` · `SVGElement`"],
  ["a tag with documentation keeps it",
    hover("(property) JSX.HTMLElementTags.b: JSX.HTMLAttributes<HTMLElement>", "Bold text.", url(`${mdn}/HTML/Element/b`)),
    `\`<b>\` · \`HTMLElement\`\n\nBold text.\n\n[MDN Reference](${mdn}/HTML/Element/b)`],
  ["any other hover keeps its type; its @url tags are links",
    hover("(property) onClick?: JSX.EventHandlerUnion<HTMLButtonElement, MouseEvent>", "", url(`${mdn}/API/Element/click_event`), url("https://example.com/docs/click")),
    `${fence("(property) onClick?: JSX.EventHandlerUnion<HTMLButtonElement, MouseEvent>")}\n\n[MDN Reference](${mdn}/API/Element/click_event) · [click](https://example.com/docs/click)`],
  ["a hover without tags is left as it is",
    `${fence("const subtotal: number")}\n\nThe cart's total.\n\n*@returns* — a number`,
    `${fence("const subtotal: number")}\n\nThe cart's total.\n\n*@returns* — a number`],
];

let fail = 0;
for (const [name, input, expected] of cases) {
  try { assert.strictEqual(shortHover(input), expected); console.log(`  ✓ ${name}`); } catch (e) { fail++; console.log(`  ✗ ${name}\n${e.message}`); }
}
process.exit(fail ? 1 : 0);
