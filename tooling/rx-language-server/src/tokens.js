// Semantic tokens that say what `.rx` knows and TypeScript does not. In the projection a source and an equation are
// both a `const` (`const cart = __.typed<Line[]>([])`, `const count = __.eq(…, true)`), so TypeScript's tokens call
// both `variable` with `readonly`, and an editor that draws semantic tokens over its grammar's colours shows state and
// derived values alike. Each such token gets a modifier of its own here, `source` or `equation`, wherever the name is
// read or written, in the module that declares it and in one that imports it.

const { URI } = require("vscode-uri");

/** The modifiers this adds to the legend. */
const MODIFIERS = ["source", "equation"];

/** The projection's helper a declaration is initialised with (`project.rs`), and the modifier its name gets. */
const HELPERS = { typed: "source", src: "source", eq: "equation" };

/** The modifier for the name at `node`: its declaration, followed through an import, is a `const` initialised with one of the helpers. */
function roleOf(ts, checker, node) {
  let symbol = ts.isShorthandPropertyAssignment(node.parent) ? checker.getShorthandAssignmentValueSymbol(node.parent) : checker.getSymbolAtLocation(node);
  if (!symbol) return undefined;
  if (symbol.flags & ts.SymbolFlags.Alias) symbol = checker.getAliasedSymbol(symbol);
  let declaration = symbol.valueDeclaration;
  if (!declaration || !ts.isVariableDeclaration(declaration)) return undefined;
  const call = declaration.initializer;
  if (!call || !ts.isCallExpression(call)) return undefined;
  const helper = call.expression;
  if (!ts.isPropertyAccessExpression(helper) || !ts.isIdentifier(helper.expression) || helper.expression.text !== "__") return undefined;
  return HELPERS[helper.name.text];
}

/** Adds the modifiers to `tokens` (`[line, character, length, type, modifiers]`, as the TypeScript service gives
 *  them for `document`, the projection). */
function mark(ts, languageService, fileName, document, legend, tokens) {
  const variable = legend.tokenTypes.indexOf("variable");
  const bits = {};
  for (const m of MODIFIERS) { const i = legend.tokenModifiers.indexOf(m); if (i >= 0) bits[m] = 1 << i; }
  const program = languageService.getProgram();
  const file = program?.getSourceFile(fileName);
  if (!file || variable < 0) return;
  const checker = program.getTypeChecker();
  const names = new Map();
  const visit = node => { if (ts.isIdentifier(node)) names.set(node.getStart(file), node); ts.forEachChild(node, visit); };
  visit(file);
  for (const token of tokens) {
    if (token[3] !== variable) continue;
    const node = names.get(document.offsetAt({ line: token[0], character: token[1] }));
    if (!node) continue;
    const role = roleOf(ts, checker, node);
    if (role && bits[role]) token[4] |= bits[role];
  }
}

/** The services, with the legend's two modifiers more and TypeScript's tokens marked with them.
 *  @param {typeof import("typescript")} ts */
function withRxTokens(ts, services) {
  return services.map(service => {
    const provider = service.capabilities?.semanticTokensProvider;
    if (!provider?.legend) return service;
    const legend = { ...provider.legend, tokenModifiers: [...provider.legend.tokenModifiers, ...MODIFIERS] };
    return {
      ...service,
      capabilities: { ...service.capabilities, semanticTokensProvider: { ...provider, legend } },
      create(context, ...rest) {
        const instance = service.create(context, ...rest);
        if (!instance.provideDocumentSemanticTokens) return instance;
        const provide = instance.provideDocumentSemanticTokens.bind(instance);
        return {
          ...instance,
          async provideDocumentSemanticTokens(document, range, legend, ...more) {
            const tokens = await provide(document, range, legend, ...more);
            if (!tokens?.length) return tokens;
            try {
              const fileName = instance.provide["typescript/documentFileName"](URI.parse(document.uri));
              mark(ts, instance.provide["typescript/languageService"](), fileName, document, legend, tokens);
            } catch (e) {
              console.error(`rx: marking semantic tokens of ${document.uri} failed: ${e?.stack ?? e}`); // TypeScript's stay
            }
            return tokens;
          },
        };
      },
    };
  });
}

module.exports = { withRxTokens, MODIFIERS };
