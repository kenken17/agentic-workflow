# Refactoring Techniques Reference

## When to Apply Each Technique

### Extract Function
- Block of code doing a distinct task
- Function is too long (> 40 lines)
- Logic needs a name to be understood
- Block is duplicated elsewhere

### Rename
- Name doesn't describe what it does
- Name is misleading
- Name uses inconsistent convention
- Variable scope is too large for its name

### Simplify Conditional
- Nesting > 3 levels deep
- Boolean expression with > 3 terms
- If/else chains that could be early returns
- Switch statements that could be dictionaries/maps

### Remove Duplication
- Same logic in 2+ places
- Similar logic with slight variations (extract the common part)
- Copy-pasted code blocks

### Move
- Function in wrong module/layer
- Test in wrong file
- Configuration in wrong place
- Constants defined far from usage

### Replace Pattern
- Deprecated API calls
- Manual implementations of stdlib functions
- Inefficient data structures (list where set would work)
- Old syntax (e.g. `.then()` chains where async/await is clearer)

## Metrics for "Done"

- Tests pass at same rate as baseline
- Lint passes
- No new TODO comments added
- Diff is minimal — only the intend changes are present
- Function count went up (smaller functions) or complexity metrics improved