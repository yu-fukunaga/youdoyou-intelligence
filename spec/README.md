# About spec/

Directory for spec files that record the purpose/background and implementation details of a task.

This assumes a personal-development workflow: it's mainly a scratchpad for not forgetting things I want to do or have thought through.
Only tasks that have been implemented and committed get moved to `spec/done/` and pushed to remote.

Intended to be viewed as a kanban board via the VS Code extension [`LachyFS.kanban-markdown`](https://marketplace.visualstudio.com/items?itemName=LachyFS.kanban-markdown).


## Extension settings

Baseline config below; adjust as needed.
```jsonc
"kanban-markdown.featuresDirectory": "spec",
"kanban-markdown.columns": [
  {
    "id": "backlog",
    "name": "Backlog",
    "color": "#ff7a7a"
  },
  {
    "id": "in-progress",
    "name": "In Progress",
    "color": "#ffff00"
  },
  {
    "id": "done",
    "name": "Done",
    "color": "#00bfff"
  }
]
```

## Layout

- `spec/*.md` — Unfinished specs. Just accumulated locally, excluded from git via `.gitignore`, never committed
- `spec/done/*.md` — Only tasks that have been implemented and committed get moved here. Tracked in git and kept in the repo's history. This `done` folder is the only part anyone else ever sees

Once a spec's implementation is done and the code is committed, move the file from `spec/` to `spec/done/`.

## Granularity

Not a strict rule, but roughly one spec per PR is the target granularity.

## Creation / naming convention

See the [spec-write skill](../.claude/skills/spec-write/SKILL.md) for how to write a spec (file naming, frontmatter fields, body format).
