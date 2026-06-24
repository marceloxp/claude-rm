# claude-rm

A safe deletion command that moves a single file to the system trash instead of
permanently deleting it. It is **explicit** — it does not alias or override `rm`.

Under the hood it delegates to `gio trash`, so files land in the FreeDesktop
trash with their original path and deletion date recorded, and can be restored.

## Disclaimer

This tool is provided **as is, without warranty of any kind**. Installing and
using it — including configuring any AI agent (such as Claude) to use it, and
relying on the `rm` block — is **entirely your own responsibility**. The author
is **not responsible** for how Claude or any other tool behaves in
your environment, nor for any data loss, damage, or other consequence arising
from its use. If you need a guarantee, verify the behavior yourself (see
[Verifying the block is active](#verifying-the-block-is-active)).

## Requirements

- `gio` (package `libglib2.0-bin`, present on most Linux desktops).

## Installation

There are two ways to install. Pick one.

### Option 1 — Let your Claude install it (recommended)

This repo ships a guided playbook so an AI agent can both install the tool **and**
enforce the rule *"never run `rm`, only `claude-rm`"* in your environment. From
your Claude prompt — even while working in another project — type:

```
Install this tool: @/absolute/path/to/claude-rm/INSTALL.md
```

(Replace `/absolute/path/to/claude-rm` with where you cloned this repo.)

Claude will install the executable, ask whether you want the `rm` block **global**
(all sessions) or **only your current project**, set up the `PreToolUse` hook that
enforces it, and verify it works. See [`INSTALL.md`](INSTALL.md) for the full
playbook and [`hooks/block-rm.sh`](hooks/block-rm.sh) for the hook itself.

> Instructions alone only *suggest* using `claude-rm`; the **hook** is what
> actually prevents `rm`. Option 1 installs both. Option 2 below installs only
> the tool — add the hook yourself if you want the guarantee.

### Option 2 — Install manually

`claude-rm` is a standalone executable. Put it on your `PATH`:

```bash
chmod +x claude-rm
sudo install claude-rm /usr/local/bin/   # or: ln -s "$PWD/claude-rm" ~/.local/bin/claude-rm
```

`claude-rm` **must be on your `PATH`** — both choices above do that. Confirm with
`command -v claude-rm`.

To also enforce the "never `rm`" rule yourself, install the `PreToolUse` hook from
[`hooks/block-rm.sh`](hooks/block-rm.sh) into your `~/.claude/settings.json`
(global) or a project's `.claude/settings.json`. The steps in
[`INSTALL.md`](INSTALL.md) work fine to do by hand.

## Verifying the block is active

To check whether your Claude is actually blocking `rm` — **safely, so that
nothing is destroyed even if the block isn't working** — ask it to run `rm`
against a file that does not exist:

```bash
rm /tmp/claude-rm-block-test-does-not-exist
```

- **Block active:** the command is denied with the hook's message, before `rm`
  ever runs.
- **Block NOT active:** `rm` runs but only reports `No such file or directory` —
  there was nothing to delete, so nothing is lost. That's your signal the hook
  isn't installed in this scope.

Never test with a real file: if the block were missing, a real `rm` would delete
it for good.

## Usage

```bash
claude-rm <file>     # move one file to the trash
claude-rm -h         # show help
```

By design it accepts **exactly one file** and **refuses directories**.

```bash
claude-rm notes.txt
# Moved to trash: notes.txt
```

## Restoring & managing the trash

Since `gio` records each file's original location, you can restore or inspect
the trash with the standard tooling:

```bash
gio trash --list                       # list trashed files and their origins
gio trash --restore /path/to/notes.txt # restore a file to where it came from
gio trash --empty                      # empty the trash
```

## Notes

- Files with the same name never overwrite each other — `gio` renames
  duplicates (e.g. `dup.txt`, `dup.2.txt`) while keeping each origin.
- Directories and multiple-file/glob deletions are intentionally **not**
  supported.
