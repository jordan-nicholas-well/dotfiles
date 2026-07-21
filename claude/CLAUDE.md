# Code style — all projects

## Comments
- Keep code comments to a minimum. Prefer self-explanatory code over explanation.
- Only comment what the code cannot say: a non-obvious constraint, an external
  gotcha, or a "this looks wrong but is deliberate because X".
- Never narrate what the next line does, why a change is correct, or the
  history of how the code got here (that belongs in the commit message or PR
  description, not the code).
- One short comment beats a paragraph. No banner/section comments in new code
  unless the file already uses them.
- The same applies to YAML/config/workflow files: a one-line pointer is fine;
  multi-paragraph rationale blocks are not.
- Never put ticket references (Jira keys, issue numbers) in code or comments —
  they go stale and mean nothing to later readers. Commit messages and PR
  titles/descriptions may reference tickets per the repo's convention.
