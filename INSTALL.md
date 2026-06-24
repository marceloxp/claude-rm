# Claude-assisted installation

> **For the human:** you don't have to install anything by hand. In your Claude
> prompt — even from another project — type:
>
> > **`Install this tool: @/absolute/path/to/claude-rm/INSTALL.md`**
>
> (Replace `/absolute/path/to/claude-rm` with where you cloned this repo.)
>
> The rest of this file is a playbook for Claude to run with you. If you'd rather
> set it up yourself, see **Manual installation** in the [README](README.md).

---

## For the Claude reading this: installation instructions

You are installing `claude-rm` in this environment. **End goal:** after install,
*you* (and any future Claude in this scope) must **never run `rm`** — to delete a
file you use `claude-rm <file>`, which moves **one** file (never a directory) to
the system's restorable trash.

**Path note (read first):** the user may have invoked this from a *different*
project, so their current working directory is probably **not** this repo. The
files referenced below — the `claude-rm` executable and `hooks/block-rm.sh` —
live in the **same directory as this `INSTALL.md`**. Resolve them relative to
*this file's* location, not the user's cwd.

This requires **two things**, and the second is what actually enforces the rule:

1. **The `claude-rm` executable** on the `PATH` (the tool).
2. **A `PreToolUse` hook** that *blocks* `rm` and redirects you to `claude-rm`
   (the enforcement). Without the hook this is only a suggestion that can be
   ignored — **do not skip the hook.**

Follow the steps in order. Ask the user where the playbook says to ask; do not
decide the scope on your own.

### Step 0 — Prerequisite

Confirm `gio` exists (`command -v gio`). If it doesn't, tell the user to install
the `libglib2.0-bin` package and stop here.

### Step 1 — Install the executable

Put the `claude-rm` file (in this repo's root, next to this INSTALL.md) on the
user's `PATH`. Prefer, in order:

- `~/.local/bin/claude-rm` (if `~/.local/bin` is on `PATH`) — no `sudo`.
- `/usr/local/bin/claude-rm` — needs `sudo`, ask the user.

Ensure `chmod +x`. Confirm with `command -v claude-rm`.

### Step 2 — ASK for the block scope

Ask the user which scope they want for the "never `rm`" rule:

- **(A) Global** — applies to *all* of this user's sessions/projects. Edits
  `~/.claude/settings.json`. The strong choice for "never run `rm` anywhere
  again".
- **(B) This project only** — applies only in the user's current project. Edits
  that project's `.claude/settings.json`. When the project is cloned/opened,
  Claude Code asks the user to **approve the hooks**; warn them about that.

Do not proceed without an answer.

### Step 3 — Install the hook (the enforcement)

Use the ready-made hook at `hooks/block-rm.sh` (next to this INSTALL.md). It
blocks `rm` in command position and **lets `claude-rm` through**.

**Important when editing `settings.json`:** back it up first, and **merge** with
`jq` — never overwrite an existing settings file (the user may have other hooks,
such as a global "never empty the trash" rule). Add **two** items:

1. Under `hooks.PreToolUse`, a `Bash` matcher pointing at the installed path of
   `block-rm.sh`.
2. Under `permissions.deny`, the entry `"Bash(rm:*)"` (belt and suspenders;
   `claude-rm` does not match the `rm` prefix).

- **Global (A):** copy `hooks/block-rm.sh` to `~/.claude/hooks/block-rm.sh`
  (`chmod +x`) and merge into `~/.claude/settings.json`.
- **Project (B):** copy it to the project's `.claude/hooks/block-rm.sh` and merge
  into the project's `.claude/settings.json` (you can use `$CLAUDE_PROJECT_DIR`
  in the hook command path for a project-relative path).

### Step 4 — Teach the positive behavior

Add a short line to the `CLAUDE.md` of the chosen scope (global
`~/.claude/CLAUDE.md` or the project's):

> To delete files, use `claude-rm <file>` (one at a time, no directories). Never
> use `rm`.

This makes you *prefer* `claude-rm` naturally; the hook is the safety net.

### Step 5 — VERIFY (do not skip)

Prove it's active **without deleting anything**, by feeding the hook simulated
input:

```bash
H=<installed-path>/block-rm.sh
# rm must be BLOCKED (prints JSON with permissionDecision=deny):
echo '{"tool_input":{"command":"rm foo.txt"}}' | bash "$H"
# claude-rm must PASS (empty output = allowed):
echo '{"tool_input":{"command":"claude-rm foo.txt"}}' | bash "$H"
```

Then confirm the **live** harness block, **safely**: run `rm` via the Bash tool
against a file that does not exist, so nothing is destroyed even if the block
isn't working:

```bash
rm /tmp/claude-rm-block-test-does-not-exist
```

- If the hook is active, the harness denies it with the hook's message.
- If it somehow runs, `rm` only reports `No such file or directory` — nothing was
  lost — and that tells you the hook isn't active in this scope; fix Step 3.

Never test the live block with a real file. Only after the block is confirmed,
tell the user you're done.

### Uninstall

Remove the hook item and the `Bash(rm:*)` entry from the chosen scope's
`settings.json`, and delete the installed `block-rm.sh`. The `claude-rm`
executable can stay.
