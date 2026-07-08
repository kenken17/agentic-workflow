# Code Review Checklist Reference

Expanded checklist for thorough code review. Load this for complex reviews.

## Language-Specific

### Python
- [ ] Type hints on public functions
- [ ] No mutable default arguments
- [ ] Context managers for resources (open, locks)
- [ ] No bare `except:` — catch specific exceptions
- [ ] list/dict comprehensions not overused to the point of unreadability
- [ ] `if __name__ == "__main__":` guard for scripts

### JavaScript/TypeScript
- [ ] No `var` — use `const`/`let`
- [ ] Async/await over raw promises where possible
- [ ] No `any` type without justification (TS)
- [ ] Proper error boundaries / try-catch
- [ ] No console.log in committed code (use proper logging)

### Go
- [ ] Error checked, not ignored (`_ = err`)
- [ ] `defer` for cleanup
- [ ] No goroutine leaks (context cancellation)
- [ ] Struct not exported unnecessarily
- [ ] Interface defined at consumer, not producer

### Rust
- [ ] No unnecessary `.clone()` calls
- [ ] `Result` handled, no `.unwrap()` on fallible paths
- [ ] Lifetimes not overly complex
- [ ] No `unsafe` without safety comments

## Architecture
- [ ] Changes follow existing patterns
- [ ] No circular dependencies introduced
- [ ] Public API changes documented
- [ ] Breaking changes called out explicitly

## Database
- [ ] Migrations are reversible
- [ ] No raw SQL without parameterization
- [ ] Index changes documented
- [ ] No N+1 query patterns