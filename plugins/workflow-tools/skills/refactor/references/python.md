# Python Refactoring Patterns

Emergent structural problems in Python codebases and how to fix them.

## The God Class

**How it happens:** A class starts as a focused service. Over months, methods get added because "this class already handles users." It now manages user CRUD, email notifications, permission checks, and audit logging. It has 20+ methods and depends on half the codebase.

**The real problem:** You cannot reuse the permission logic without importing the entire class. Testing one method requires mocking 8 dependencies. New developers cannot find where a behavior lives because everything is in one place.

**Fix:** Extract responsibility-focused classes. `UserService` handles CRUD. `PermissionChecker` handles access control. `AuditLogger` handles logging. Each class has a single reason to change.

**How to identify:** Look for classes where methods cluster into groups that do not interact with each other. Those groups are separate responsibilities waiting to be extracted.

## Module That Outgrew Itself

**How it happens:** `models.py` starts with 3 dataclasses. Then 10 more. Then utility functions related to those models. Then validation logic. It is now 800 lines and "models" does not describe what it contains.

**The real problem:** Finding a specific type requires scanning the whole file. The module's imports pull in unrelated dependencies. Changes to one model risk merge conflicts with someone editing another.

**Fix:** Convert the module into a package. `models.py` becomes `models/__init__.py` + submodules. Re-export from `__init__.py` so existing `from models import X` statements keep working:
```python
# models/__init__.py
from models.user import User, UserProfile
from models.order import Order, LineItem
__all__ = ["User", "UserProfile", "Order", "LineItem"]
```

**How to identify:** A module where you instinctively use Ctrl+F to find things. Multiple unrelated clusters of definitions that only interact at the edges.

## Feature Envy

**How it happens:** A method on `OrderService` spends most of its body accessing fields of `User`: checking `user.role`, reading `user.preferences`, validating `user.subscription_tier`. It knows more about `User` internals than `User` itself does.

**The real problem:** `OrderService` is coupled to `User`'s internal structure. If `User` changes how roles work, `OrderService` breaks. The logic is in the wrong place.

**Fix:** Move the method (or the relevant logic) to the class whose data it primarily uses. `User` should expose a method like `can_place_order()` rather than having `OrderService` inspect its fields.

**How to identify:** Methods that access more attributes from another object than from `self`.

## Wildcard Imports Hiding Dependencies

**How it happens:** `from utils import *` saves typing. Then another `from helpers import *`. Now the module's namespace has 50 names and you cannot tell where any of them come from. A name collision silently overwrites a function. A new export from `utils` unexpectedly shadows a local name.

**The real problem:** Dependencies are invisible. Removing a function from `utils` might break this module, but you cannot tell without running it. IDE support breaks because the source of names is ambiguous.

**Fix:** Use explicit named imports: `from utils import parse_date, format_currency`. If the import list is long, that is a sign the module depends on too much.

**How to identify:** Search for `import *` statements.

## Deep Relative Imports

**How it happens:** A module at `mypackage/services/orders/processing.py` needs something from `mypackage/core/auth.py`. It uses `from ...core.auth import authenticate`. The three dots make the relationship opaque and fragile to file moves.

**The real problem:** Relative imports encode the directory structure into the code. Moving a file requires updating every relative import chain. Deep relative paths (`...`, `....`) are nearly impossible to parse by reading.

**Fix:** Use absolute imports: `from mypackage.core.auth import authenticate`. Relative imports are acceptable within the same package, but only one level deep (`from .sibling import X`).

**How to identify:** Any import with more than one dot (`..` or deeper).

## Mutable Default Arguments

**How it happens:** A function uses `def process(items=[])` for a default empty list. It looks natural. But Python evaluates default arguments once at function definition. Every call that uses the default shares the same list object. Appending in one call affects all future calls.

**The real problem:** State leaks between function calls invisibly. This creates bugs that are hard to reproduce because they depend on call history.

**Fix:** Use `None` as the sentinel:
```python
def process(items=None):
    items = items if items is not None else []
```

**How to identify:** Search for mutable default arguments: `def.*=\[\]`, `def.*=\{\}`, `def.*=set\(\)`.

## The `__init__.py` That Does Too Much

**How it happens:** Someone adds imports to `__init__.py` for convenience: "just import from the package name." Then every submodule's exports get added. Now importing the package triggers importing every submodule, including heavy ones with their own dependencies. Import time balloons.

**The real problem:** Importing one symbol from the package loads everything. Tests slow down. Startup time increases. Circular import errors appear as the dependency graph grows.

**Fix:** Keep `__init__.py` minimal. Declare `__all__` for the public API. Consider lazy imports for heavy submodules (PEP 810, or the `lazy_loader` library).

**How to identify:** Measure import time with `python -X importtime`. Look for `__init__.py` files with many import statements.

## Idiomatic Patterns

When refactoring Python code, apply these idiomatic patterns:

- Use `@dataclass` (or `@dataclass(frozen=True)`) for data containers instead of plain classes with manual `__init__`.
- Use context managers (`with`) for any resource that needs cleanup (files, connections, locks).
- Use `isinstance()` instead of `type()` for type checking.
- Use `pathlib.Path` instead of `os.path` string manipulation.
- Use f-strings instead of `%` formatting or `.format()`.
- Use `enumerate()` instead of manual index tracking.
- Use dictionary unpacking (`{**defaults, **overrides}`) instead of manual merge loops.

## Sources

- [The Hitchhiker's Guide to Python](https://docs.python-guide.org/writing/structure/)
- [The Little Book of Python Anti-Patterns](https://docs.quantifiedcode.com/python-anti-patterns/)
- [Real Python: Refactoring Python Applications](https://realpython.com/python-refactoring/)
- [Dagster: How to Structure Python Projects](https://dagster.io/blog/python-project-best-practices)
- [PEP 810: Lazy Imports](https://peps.python.org/pep-0810/)
