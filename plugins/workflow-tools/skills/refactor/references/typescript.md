# TypeScript Refactoring Patterns

Emergent structural problems in TypeScript codebases and how to fix them.

## The God Component

**How it happens:** A React component starts simple. Then state management gets added. Then API calls. Then conditional rendering for 5 different states. Then form handling. It is now 400 lines and manages everything.

**The real problem:** You cannot understand what the component renders without reading through all the state logic. You cannot test the business logic without rendering the UI. Every change risks breaking something unrelated.

**Fix:** Separate concerns:
- Extract state/effect logic into custom hooks. The hook manages the "what", the component manages the "how it looks."
- Extract large conditional branches into separate child components.
- Extract pure data transformations into plain functions outside the component.

**How to identify:** A component with more than 3-4 `useState` calls, or `useEffect` calls that handle different concerns, or conditional blocks that render substantially different UI.

## Barrel File Dependency Explosion

**How it happens:** Someone adds an `index.ts` that re-exports from siblings for cleaner imports. Other modules import from the barrel. Now importing one symbol pulls the entire module graph through the barrel. Build times slow. Test runs inflate. Circular dependencies appear.

**The real problem:** Barrels flatten the dependency graph. The bundler cannot tree-shake effectively because the barrel connects everything. A test that imports one function ends up loading the entire module.

**Fix:** Delete barrel files in application code. Import directly from source modules. Use TypeScript path aliases in `tsconfig.json` for cleaner paths:
```json
{ "paths": { "@ui/*": ["src/components/ui/*"] } }
```

**When barrels are fine:** Component libraries where modules are independent and consumers legitimately need a single entry point.

**How to identify:** Check if `index.ts` files exist that only re-export. Trace what a single import actually pulls in.

## Prop Drilling Through Layers

**How it happens:** A parent component owns some state. A grandchild needs it. Rather than restructuring, the state gets passed through 3 intermediate components that do not use it. Every new piece of shared state adds another prop threaded through the same intermediaries.

**The real problem:** Intermediate components are coupled to data they do not care about. Changing the shape of the state requires updating every component in the chain. The data flow is hard to trace.

**Fix (in order of preference):**
1. Fewer components. If an intermediate component exists only to wrap, inline it.
2. Merge related props into an object. Pass `user` instead of `firstName`, `lastName`, `email`.
3. Children pattern. Render the consuming component as a child of the state owner directly.
4. Context. For truly cross-cutting concerns (theme, auth, locale) that 3+ levels need.

**How to identify:** Look for props that pass unchanged through a component's children without being used by that component.

## Type Duplication Instead of Derivation

**How it happens:** A developer needs a subset of `User` for a form. They copy the fields into a new interface. Later `User` adds a field, but the form interface is stale. Or the field name changes in `User` but not in the form interface. Bugs follow.

**The real problem:** The type system cannot help when types are independently defined. Changes to the source type do not propagate to the copies.

**Fix:** Derive types from their source of truth:
- `Pick<User, 'name' | 'email'>` instead of copying fields.
- `ReturnType<typeof fetchUser>` instead of manually defining the response shape.
- `Parameters<typeof fn>` to stay in sync with function signatures.
- Lookup types (`User["role"]`) when you need a single field's type.

**How to identify:** Search for interfaces that share 3+ fields with another interface. These are likely copies that should be derived.

## Module That Grew Into a Junk Drawer

**How it happens:** `utils.ts` starts with one helper. Then 20 more unrelated functions accumulate. The module has no cohesion, it is just "stuff that did not fit elsewhere."

**The real problem:** `utils` depends on everything (it needs types, APIs, and libraries for its various functions) and everything depends on `utils`. It becomes a coupling hub. Finding what you need requires reading the entire file.

**Fix:** Move each function to the module that uses it. If `formatDate` is only used in `reporting/`, it belongs there. If truly shared across domains, name the module after what it does: `date-format.ts`, `string-utils.ts`.

**How to identify:** A module with more than 5 exports that serve unrelated purposes.

## Mutable Module State

**How it happens:** A module exports a `let` variable or an object whose properties get mutated from multiple places. It works as a quick global store. Then two features write to it, and the order of writes matters.

**The real problem:** Any module can import and mutate the state. The mutation order is implicit. Tests interfere with each other.

**Fix:** Export `const` values. If state needs to be shared, encapsulate it: export functions that manage the state, not the state itself. For React, use context or a state management library.

**How to identify:** Search for `export let` or exported objects that get mutated (`exported.field = ...`).

## Complexity as a Signal

High cognitive complexity in a function points to tangled logic: deeply nested conditionals, long chains of ternaries, interleaved async flows. Use it as a starting point to find functions that mix concerns.

When a function is complex, ask: what distinct things is it doing? A function that validates, transforms, and persists should be three functions.

## Idiomatic Patterns

When refactoring TypeScript code, apply these idiomatic patterns:

- **Discriminated unions over type assertions.** Use `type Result = { ok: true; value: T } | { ok: false; error: Error }` instead of casting with `as`.
- **Const assertions for literal types.** Use `as const` for fixed configuration objects to get narrow types automatically.
- **Satisfies operator.** Use `satisfies` to validate a value conforms to a type without widening it: `const config = { ... } satisfies Config`.
- **Nullish coalescing and optional chaining.** Use `??` and `?.` instead of verbose null checks. But do not chain more than 3 levels deep, that is a sign of deep coupling.
- **Exhaustive switches with `never`.** When switching on a discriminated union, add a default case that assigns to `never`. The compiler will error if a variant is unhandled.
- **Named parameters via objects.** When a function takes 3+ parameters of the same type (multiple strings, multiple booleans), use an options object. This prevents argument order bugs.

## Sources

- [Google TypeScript Style Guide](https://google.github.io/styleguide/tsguide.html)
- [Atlassian: Faster builds removing barrel files](https://www.atlassian.com/blog/atlassian-engineering/faster-builds-when-removing-barrel-files)
- [TkDodo: Please Stop Using Barrel Files](https://tkdodo.eu/blog/please-stop-using-barrel-files)
- [Tomasz Ducin: TypeScript Anti-Patterns](https://ducin.dev/typescript-anti-patterns)
- [Alex Kondov: Refactoring a Messy React Component](https://alexkondov.com/refactoring-a-messy-react-component/)
