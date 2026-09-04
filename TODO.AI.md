# TODO

Pre-existing `script-lint` violations found while linting an unrelated
diff (2026-09-04, AUDIT.AI.md #40 companion commit). Not in the lines
that commit touched (a 3-line removal of the 1024-bit generation step) -
logged here rather than fixed inline to keep that commit's diff scoped
to its actual change.

## root/.local/bin/root_dhparams.sh

- [ ] Header `##@Version` (202305090019-git) has no matching `VERSION=`
      assignment in the script body - add one or drop the header field
- [ ] `DHDIR="${DHDIR:-...}"` on line 25 is read as a caller-settable
      override but uses a bare name; rename to the script-name-prefixed
      `ROOT_DHPARAMS_DHDIR` throughout the file
