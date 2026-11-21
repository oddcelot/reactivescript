// What an editor's hover on a `.rx` keyword says: the form, one or two lines from guide/, the rules, a link to the guide.
// The projection drops the keywords (`latest x` is `x` in the TSX), so TypeScript has nothing to say about them.

const guide = (page, section) => `https://github.com/solidjs/reactivescript/blob/main/guide/${page}#${section}`;
const LANG = s => guide("language.md", s);
const REF = s => guide("reference.md", s);
const ASYNC = s => guide("async.md", s);

/** keyword → `{ form, text, rules?, link }`. Only the words `.rx` adds or gives a meaning of its own. */
const KEYWORDS = {
  source: {
    form: "source x := v",
    text: "State: the only kind of name that is written, with `:=`, in a handler or an action. `source x = e` is a client layer over `e`, reset when `e`'s answer changes.",
    rules: ["W-1", "ST-5"],
    link: LANG("declarations"),
  },
  await: {
    form: "x = await f(a)",
    text: "In an equation: the answer to `f(a)`, asked again when `a` changes, stale answers dropped. It can be pending and can fail, so its readers sit in `loading` and `errored` regions. `await e -> v` shows `v` until the first answer.",
    rules: ["R-7"],
    link: ASYNC("1-reading-from-the-server-an-equation"),
  },
  "pending?": {
    form: "pending? x",
    text: "`true` while a new answer for `x` is out, or while an action that `affects x` is in flight. Shows work in progress without a fallback. It takes no failure.",
    rules: ["R-9", "AC-5"],
    link: REF("holds-what-the-screen-shows-while-work-is-out"),
  },
  latest: {
    form: "latest x",
    text: "The value `x` is moving to, before its answer lands. Only this read looks ahead: a plain read of `x` beside it shows what is on screen. `loading on(latest x)` shows its fallback at once.",
    rules: ["R-9", "R-11", "H-6"],
    link: REF("holds-what-the-screen-shows-while-work-is-out"),
  },
  peek: {
    form: "peek(x)",
    text: "`x` read once, without depending on it. For a one-time seed: `source draft := peek(props.x)`.",
    link: LANG("expressions"),
  },
  guess: {
    form: "guess x := e",
    text: "Shown now, kept until the action's change commits or `x`'s own answer differs. Reverts if the action fails. Only in an action.",
    rules: ["AC-3", "H-11"],
    link: REF("actions"),
  },
  refresh: {
    form: "refresh x",
    text: "Asks `x` again, quietly: no `pending?`, and the old value stays up until the new one lands. In an action, the answer lands with the action's commit.",
    rules: ["AC-4"],
    link: REF("actions"),
  },
  affects: {
    form: "affects x",
    text: "`pending? x` is `true` until this action's change commits.",
    rules: ["AC-5"],
    link: REF("actions"),
  },
  action: {
    form: "action f(a) { … }",
    text: "One change across its awaits: every write in it is held until it returns. A failure inside it is caught there, with `try`/`catch`.",
    rules: ["AC-1", "AC-7"],
    link: REF("actions"),
  },
  effect: {
    form: "effect (a, b) { … }",
    text: "Runs after an instant in which `a` or `b` changed, once, with `$0`, `$1` the values. Its writes are a new instant, `return () => …` is its cleanup, and it may not write what it reads.",
    rules: ["EF-2", "EF-3", "EF-5", "C-3"],
    link: REF("writes-and-instants"),
  },
  fn: {
    form: "fn f(a) => …",
    text: "A pure function. One that writes or awaits is an `action`; one that renders is a `component`.",
    link: LANG("declarations"),
  },
  component: {
    form: "component C(props) { … }",
    text: "Declarations, then markup. Its parameters are read-only, and `props.x` stays live.",
    link: LANG("components"),
  },
  error: {
    form: "error NotFound(id) => …",
    text: "A failure class. `throw NotFound(id)` makes a failure value; `errored fallback(e: NotFound)` takes only that class.",
    rules: ["R-f-4"],
    link: REF("failures"),
  },
  loading: {
    form: "loading on(x) fallback { … } { … }",
    text: "Shows its fallback while armed: before its content first showed, and again each time its `on(x)` value changes. Otherwise a change below it holds.",
    rules: ["H-5"],
    link: REF("holds-what-the-screen-shows-while-work-is-out"),
  },
  errored: {
    form: "errored fallback(e) { … } { … }",
    text: "Shows its fallback when a value read inside it fails. Every reader of a value that can fail needs one above it. `fallback(e: NotFound)` takes only that class.",
    rules: ["R-f-5", "R-f-4"],
    link: REF("failures"),
  },
  on: {
    form: "loading on(x)",
    text: "Arms the region again each time `x` changes. `on(latest x)` shows the fallback at once; `on(x)` shows it with `x`'s change.",
    rules: ["H-5", "H-6"],
    link: REF("holds-what-the-screen-shows-while-work-is-out"),
  },
  for: {
    form: "for r in rows { … }",
    text: "One region per row, kept by the rows' `key`.",
    rules: ["ST-4"],
    link: REF("collections"),
  },
  key: {
    form: "source xs key id = …",
    text: "Keeps each row's identity by `id` across answers. Write one row with `xs[i].field := v`.",
    rules: ["ST-4", "W-6"],
    link: REF("collections"),
  },
  use: {
    form: "use name",
    text: "The nearest `provide name` above, read-only.",
    link: LANG("expressions"),
  },
  provide: {
    form: "provide name = e",
    text: "Gives `e` to every `use name` below. Readers can't write it: provide an action to let them.",
    link: LANG("expressions"),
  },
  context: {
    form: "context name: T = d",
    text: "Declares a context: given with `provide name = e`, read with `use name`.",
    link: LANG("expressions"),
  },
  pure: {
    form: "import pure { f } from …",
    text: "`f` is safe to call from an equation: a loader, asked again when its inputs change.",
    rules: ["R-io-4"],
    link: LANG("modules"),
  },
};

/** The hover's Markdown for a keyword, or undefined for one `.rx` shares with TypeScript. */
function keywordHover(word) {
  const k = KEYWORDS[word];
  if (!k) return undefined;
  const rules = k.rules?.length ? ` · ${k.rules.join(", ")}` : "";
  return `\`${k.form}\`${rules}\n\n${k.text}\n\n[Guide](${k.link})`;
}

module.exports = { KEYWORDS, keywordHover };
