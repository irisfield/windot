---
name: commit
description: Create git commits with user approval and no Claude attribution
---

# Commit Changes

You are tasked with creating git commits for the changes made during this session.

## Process:

1. **Think about what changed:**
   - Review the conversation history and understand what was accomplished
   - Run `git status` to see current changes
   - Run `git diff` to understand the modifications
   - Consider whether changes should be one commit or multiple logical commits

2. **Plan your commit(s):**
   - Identify which files belong together by theme or concern
   - **Avoid bundling all changes into a single commit** — prefer multiple focused commits over one large one
   - **Aim for 1–3 files per commit.** If a proposed commit touches more than ~3 files, ask yourself whether it can be split further
   - **Each commit should have one clear subject.** If the message needs more than one independent clause joined by a comma, split it
   - **Separate concerns ruthlessly:** type/model changes, component rewrites, utility improvements, CSS/config tweaks should each be their own commit unless they are truly inseparable
   - Group changes by logical unit: e.g., step definition migrations together, documentation updates together, utility/helper changes together
   - Draft clear, descriptive commit messages following the format below
   - Focus on why the changes were made, not just what

3. **Present your plan to the user:**
   - List the files you plan to add for each commit
   - Show the commit message(s) you'll use
   - Ask: "I plan to create [N] commit(s) with these changes. Shall I proceed?"

4. **Execute upon confirmation:**
   - Use `git add` with specific files (never use `-A` or `.`)
   - Create commits with your planned messages
   - Show the result with `git log --oneline -n [number]`

### Rules:

- The one-line summary MUST use a **lowercase verb in past tense** (e.g., `migrated`, `updated`, `replaced`, `removed`, `refactored`)
- Keep the summary concise — describe _what_ changed and _why_ in one line; include multiple related changes separated by commas if needed
- Do NOT use imperative mood (avoid: `add`, `fix`, `update`) — use past tense instead

### When to use simple vs elaborate format:

- **Simple (one-line):** The commit does one thing and the summary fully explains it. Reading the diff would not leave questions. Examples: renaming a variable, fixing a typo, adding a single dependency, changing a default value.
- **Elaborate (summary + bullet points):** The commit touches multiple concerns, makes non-obvious choices, or the "why" is not self-evident from the diff. If someone reading `git log --oneline` would need to open the diff to understand the commit, use the elaborate format. Examples: replacing a component with a different pattern, consolidating multiple fields into one, aligning two files with each other.

**Default to elaborate when in doubt.** A bullet point that turns out to be unnecessary costs nothing; a missing explanation costs a future reader time.

### Examples:

Simple one-line:

```
added eslint with react-hooks and typescript-eslint plugins
```

```
updated default JP font order to prefer Yu Mincho
```

Elaborate:

```
aligned JP document with EN document patterns

- switched all field widths to shared constants (FIELD_WIDTH_NAME,
FIELD_WIDTH_COUNTRY) and em units instead of rem
- added inputClassName="text-center" to all fields that are centered
in the English version
- replaced multiline address fields with LabeledFullWidthField
- matched signature block, gap sizes, and spacer lines to EN layout

```

## Important:

- **NEVER add co-author information or Claude attribution**
- Commits should be authored solely by the user
- Do not include any "Generated with Claude" messages
- Do not add "Co-Authored-By" lines
- Write commit messages as if the user wrote them

## Remember:

- You have the full context of what was done in this session
- Group related changes together
- Keep commits focused and atomic when possible
- The user trusts your judgment - they asked you to commit
