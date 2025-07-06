# Git Commit Guidelines

## Commit Message Format

All commit messages **MUST** be in English only.

### Format Structure
```
<type>: <subject>

[optional body]

[optional footer]
```

### Types
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `style`: Code style changes (formatting, missing semi-colons, etc)
- `refactor`: Code refactoring
- `test`: Adding or updating tests
- `chore`: Maintenance tasks, build changes, etc

### Subject Guidelines
- Use imperative mood ("Add feature" not "Added feature")
- Keep it under 50 characters
- No period at the end
- Capitalize first letter

### Examples

#### Good commits:
```
feat: Add memory table display functionality
fix: Correct swap calculation in memory module
docs: Update installation instructions
refactor: Simplify table formatting logic
style: Fix indentation in memory.sh
test: Add memory table test script
chore: Update .gitignore
```

#### Bad commits:
```
❌ исправил таблицу памяти
❌ добавил функцию
❌ Fixed bug.
❌ update
❌ WIP
❌ фикс багов в модуле памяти
```

## Rules
1. **English only** - No Russian, Ukrainian, or other languages
2. **Imperative mood** - Write as if giving a command
3. **Be specific** - Explain what the commit does
4. **Keep it short** - Subject line under 50 characters
5. **Use conventional format** - Follow the type: subject structure

## Enforcement
- All commits must follow these guidelines
- Commits in non-English languages will be rejected
- Use descriptive subjects that explain the change
