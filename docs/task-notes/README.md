# About docs/task-notes/

Directory for task notes that record the purpose/background and implementation details of a task.

This assumes a personal-development workflow: it's mainly a scratchpad for not forgetting things I want to do or have thought through.
Only tasks that have been implemented and committed get moved to `docs/task-notes/done/` and pushed to remote.

Intended to be viewed as a kanban board via the VS Code extension [`LachyFS.kanban-markdown`](https://marketplace.visualstudio.com/items?itemName=LachyFS.kanban-markdown).


## Extension settings

Baseline config below; adjust as needed.
```jsonc
"kanban-markdown.featuresDirectory": "docs/task-notes",
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

The `done/` subfolder name is hardcoded in the extension and cannot be configured.

## Layout

- `docs/task-notes/*.md` — Unfinished task notes. Just accumulated locally, excluded from git via `.gitignore`, never committed
- `docs/task-notes/done/*.md` — Only tasks that have been implemented and committed get moved here. Tracked in git and kept in the repo's history. This `done` folder is the only part anyone else ever sees

Once a task note's implementation is done and the code is committed, move the file from `docs/task-notes/` to `docs/task-notes/done/`.

## Granularity

Not a strict rule, but roughly one task note per PR is the target granularity.

## Creation / naming convention

See the [task-note-write skill](../../.claude/skills/task-note-write/SKILL.md) for how to write a task note (file naming, frontmatter fields, body format).
