# Go Refactoring Patterns

Emergent structural problems in Go codebases and how to fix them.

## The God Struct

**How it happens:** A struct starts with 2-3 fields. Every new feature adds "just one more" dependency. After a few months it holds the database, cache, logger, mailer, config, and every service reference.

**The real problem:** Functions that receive this struct have access to everything. Nothing communicates which dependencies a function actually needs. Testing requires constructing the entire world.

**Fix:** Split into focused structs. Each component receives only the dependencies it uses. A `UserService` needs a `UserRepository` and a logger, not the entire application context.

**How to identify:** Look for structs where most methods only use 2-3 of the available fields. The unused fields are a sign the struct bundles unrelated concerns.

## Mixed Concerns in One File

**How it happens:** A file starts as `server.go` with a handler. Then someone adds request validation next to the handler because it's related. Then business logic because it's called from the handler. Then database queries because the business logic needs data. Now `server.go` has HTTP routing, validation, domain logic, and SQL in one place.

**The real problem:** To understand the HTTP layer, you wade through database queries. To change a query, you risk breaking handler routing. Concerns that change for different reasons are coupled.

**Fix:** Separate by layer. Handlers in one file delegate to services in another. Services contain business logic and call repositories. Each file has one reason to change.

**How to identify:** Read a file top to bottom. If you have to context-switch between "what protocol is this" and "what does the business rule do", the concerns are mixed.

## Package That Grew Too Wide

**How it happens:** A single package starts handling a focused domain. Over time, related-but-distinct features get added because creating a new package feels like overkill. The package now handles authentication, user profiles, permissions, and session management.

**The real problem:** Everything is in one namespace. Internal types leak between features. You cannot understand one feature without loading the context of all others. The package has no clear boundary.

**Fix:** Extract sub-packages into `internal/` when features are genuinely distinct. Auth, profiles, and sessions are separate concerns even if they all relate to "users." Use `internal/` so you can freely change the sub-package APIs later.

**How to identify:** Count the distinct "topics" a package handles. If someone new would need to understand the whole package to work on one feature, it is too wide.

**Important caveat:** Do not split prematurely. A package with many files is not automatically a problem. Only split when the concerns are genuinely distinct: they change for different reasons, serve different consumers, or create circular dependencies.

## Producer-Defined Fat Interfaces

**How it happens:** A package defines an interface matching its concrete type. Every time a new method is added to the type, it gets added to the interface. The interface now has 10+ methods, and every consumer depends on the entire surface.

**The real problem:** Consumers are coupled to methods they never call. Testing requires implementing 10 methods when only 2 are needed. Adding a method to the interface forces every mock to be updated.

**Fix:** Delete the producer-side interface. Let consumers define the smallest interface they need in their own package. A consumer that only calls `GetUser` defines a one-method `UserGetter` interface. The concrete type satisfies it implicitly.

**How to identify:** Look for interfaces defined in the same package as their only implementation. Check how many methods each consumer actually calls.

## Global State and init()

**How it happens:** Early in development, a package-level variable is convenient. A database connection, a logger, a config struct. `init()` sets it up. Other files in the package use it directly. It works fine until it doesn't.

**The real problem:** Dependencies are invisible. You cannot tell from a function signature what state it touches. Tests that run in parallel corrupt each other. Initialization order becomes fragile, a new `init()` in another file might run first.

**Fix:** Explicit dependency injection. Construct everything in `main()`, pass it down through constructors. Functions declare what they need.

**How to identify:** Search for package-level `var` declarations that hold state (connections, clients, caches). Search for `init()` functions that do more than register drivers or run compile-time checks.

## Circular Dependencies Worked Around with Interfaces

**How it happens:** Package A needs a type from package B, and package B needs a type from package A. The Go compiler rejects the cycle. So someone defines an interface in one package to break the cycle. The code compiles, but the underlying design problem remains.

**The real problem:** The two packages are not independent. The interface is a band-aid. Changes to one package still ripple into the other.

**Fix:** Extract the shared concern into a third package. Or move the shared types to a "domain" package that both depend on. Or reconsider whether these are actually two packages, they might belong together.

**How to identify:** Look for interfaces that exist only to break an import cycle, not because multiple implementations exist.

## The utils/helpers/common Package

**How it happens:** Someone writes a function that does not obviously belong to any domain package. It goes into `utils`. Then another. Then 30 more. The package becomes a junk drawer with no cohesion.

**The real problem:** `utils` has no clear responsibility. It depends on everything and everything depends on it. It is a magnet for unrelated code.

**Fix:** Move each function to the package that actually uses it. If `FormatDate` is only used by the `report` package, it belongs in `report`. If truly shared, name the package after what it does: `timeutil`, `stringconv`.

## Complexity as a Signal

High cyclomatic complexity in a function is not the problem itself, but it points to one. A function with complexity 20+ usually means mixed concerns: validation, business logic, and error handling tangled together.

Use complexity as a starting point to find functions worth examining. Then ask: what distinct responsibilities does this function handle? Extract each into a named function whose name describes the intent.

Go's explicit error handling inflates complexity numbers. A function with 5 `if err != nil` blocks is not necessarily complex, it is just verbose. Focus on functions where the branching represents genuinely different logic paths, not just error propagation.

## Idiomatic Patterns

When refactoring Go code, apply these idiomatic patterns:

- **Table-driven logic.** Replace repetitive switch/if-else blocks with a map or slice of structs. If 3+ branches do the same operation with different values, it is a table.
- **Guard clauses.** Handle error cases and edge cases with early returns at the top of a function. The happy path should not be nested inside conditionals.
- **Accept interfaces, return structs.** Functions should accept the smallest interface they need and return concrete types. This decouples consumers from implementations.
- **Functional options.** For constructors with many optional parameters, use the `WithXYZ` functional options pattern instead of config structs or builder patterns.
- **Errors are values.** Wrap errors with context using `fmt.Errorf("doing X: %w", err)`. Do not log and return the same error. Handle it or wrap it, not both.
- **Zero values are useful.** Design types so the zero value is valid and usable. A `sync.Mutex` works without initialization. A `bytes.Buffer` works empty.

## File Organization Within a Package

When splitting a file, follow Go conventions:

- Name files after the primary type or concept: `server.go` for `Server`, `client.go` for `Client`.
- Place `NewXYZ()` constructor immediately after its type definition.
- Group methods by receiver.
- Keep exported functions before unexported ones.
- Multiple related types in one file is normal and idiomatic in Go (unlike Java's one-class-per-file).

## Sources

- [Google Go Style Best Practices](https://google.github.io/styleguide/go/best-practices.html)
- [Uber Go Style Guide](https://github.com/uber-go/guide/blob/master/style.md)
- [Effective Go](https://go.dev/doc/effective_go)
- [Organizing a Go module](https://go.dev/doc/modules/layout)
- [Ben Johnson's project structure](https://medium.com/sellerapp/golang-project-structuring-ben-johnson-way-2a11035f94bc)
- [Peter Bourgon: A theory of modern Go](https://peter.bourgon.org/blog/2017/06/09/theory-of-modern-go.html)
- [Dave Cheney: Go without package scoped variables](https://dave.cheney.net/2017/06/11/go-without-package-scoped-variables)
