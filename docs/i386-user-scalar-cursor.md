# User scalar output and horizontal viewport

A simple original-User constructor control renders42 and stores the exact
`6*7;\n42\n` transcript (`build/user-scalar-document-before-v2`). Narrowing that
User to columns1–39 and entering a long alphabetic-string declaration also
passes (`user-scalar-tiled-before-v1`). Neither requires HomeSys or retirement.

The command history from the handoff case reproduces clipping while the
bootstrap is still alive (`user-scalar-tiled-before-v2`). After the BRLog helper
and conditional TaskValidate expression,6*7 executes successfully. The task's
answer is42, its type is10, and DocSave contains a separate42 line. Nevertheless
the independent glyph check fails. The39-column User's horizontal scroll and
document line_start_col are both1, hiding the leading4. This isolates an output
viewport problem from arithmetic and bootstrap lifetime.

`tests/guest/i386-user-scalar-cursor/Capture.HC` is byte-identical to that tested
capture fixture. It exports the bounded serialized document and176 I64 values:
16 state values followed by20 eight-value entry records. State contains task
identity/answer/type, document flags/x/y/cur_col, window bounds, horizontal scroll,
line_start_col/top_line_num, width and doc->win_task identity. Each entry records
type, flags, x/y, min/max column, packed tag prefix and tag length. Interpret only
min(8, tag length) prefix bytes. Buffers remain task-owned for host capture; this
fixture does not establish resource reclamation.

The first collector used nonexistent CDoc cur_x/cur_y members. Its compiler
rejection is explicitly invalid fixture evidence and is excluded; the corrected
collector uses the actual x/y fields.

A source-only ConsoleRuntime experiment replaces the prompt's manual end-cursor
assignment with original DocBottom. Compilation and independent8MiB
welcome/42/DocAllocationCheck13 pass, but the exact controlled User case remains
red: stored42, scroll1 and missing answer glyphs
(`bootstrap-prompt-bottom-cross-v1`, `bootstrap-prompt-bottom-install-v1`,
`user-scalar-tiled-after-v1`). This is not a selected repair.

The next disposable variant requests original cursor-tracking layout explicitly
at the new line before adding the next prompt. Its cross-build/instruction,
installation, identical User case, retirement workflow and8MiB User regression
are queued under `bootstrap-prompt-cursor-queue-v1`. Production source remains
pinned for native qualification. Full original CmdLinePmt/GetStr integration,
differential desktop raster/input and resource coverage are separate requirements.
