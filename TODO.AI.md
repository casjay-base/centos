# TODO

Pre-existing `script-lint` violations found while linting unrelated
diffs. Not in the lines each companion commit touched - logged here
rather than fixed inline to keep those commits' diffs scoped to their
actual changes.

## root/.local/bin/root_dhparams.sh (found 2026-09-04, AUDIT.AI.md #40
companion commit)

- [ ] Header `##@Version` (202305090019-git) has no matching `VERSION=`
      assignment in the script body - add one or drop the header field
- [ ] `DHDIR="${DHDIR:-...}"` on line 25 is read as a caller-settable
      override but uses a bare name; rename to the script-name-prefixed
      `ROOT_DHPARAMS_DHDIR` throughout the file

## root/.local/bin/run-os-update (found 2026-09-09, firewalld fix
companion commit)

- [ ] Rename internal functions to the required `__` prefix: `execute`,
      `run_grub`, `rm_if_exists` (rename definition + every call site for
      each)
- [ ] `@@Version` header (202308102203-git) does not match `VERSION=`
      (202506190941-git) — sync them
- [ ] Add `--` before the grep query at lines 82 (x2), 116 (x2), 143, 144,
      149, 153 (x2), 156, 191 (x3), 196 (x3), 218, 475 (x5), 476 (x5), 477
      (x3), 478 (x2), 543, 716, 725, 774, 778, 782, 815 (x2), 923, 926
- [ ] Bare `exit` with no code at lines 213, 575, 1057 — use
      `exit 0`/`1`/`"$?"`
- [ ] Add a `--color` flag to the argument parser
- [ ] Check the `NO_COLOR` env var
- [ ] Missing semicolon at line 1037 —
      `if [ -d "/tmp/dotfiles-personal-$USER" ] then` should be
      `if [ -d "/tmp/dotfiles-personal-$USER" ]; then`
