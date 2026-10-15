# Document-owner exit during linked rendering

```
python3 tools/test-i386-render-owner-exit.py IMAGE --out build/FRESH-owner-exit
```

This contract exercises an existing native lifecycle path. A User terminal owns
its displayed document and compiles a local dynamic-tag callback. A linked child
enters NativeGraphicsPresent, then DocRecalc on that document. The callback
confirms the owner is valid and the child holds the document lock, then yields
without returning. The owner either calls Exit or is killed externally.

Native Exit requests termination of linked children and waits for their
retirement before finishing the owner. Render-scope cleanup must therefore
release the child's document lock and frame lease before terminal cleanup
deletes the document. The child's inherited code/heap references also protect
the owner's compiled callback while its stack remains live.

Each case requires actual callback entry, no return from the canceled frame,
owner and child retirement, exact parent-heap recovery, and successful graphics
and text presentation afterward. The fixture restores the console before
returning its mask. It passes helper addresses explicitly because User source
does not resolve these names from the parent's interactive compiler session.

Both cases return mask 63 in the seventeen-command no-FPU/64 MiB session
(`build/i386-c4-render-owner-exit-lines/result.json`). Image, harness and fixture
hashes remain unchanged. The existing lifecycle implementation passes; this
checkpoint adds qualification coverage without changing kernel behavior.

During fixture development, an initialized local function-pointer declaration
with document arguments failed in the native compiler's offset parser
(`build/i386-c4-local-function-pointer-probe/result.json`). The exploratory
pinned-original control also entered its debugger in PrsOffsetOf on that
initializer (`build/i386-c1-local-function-pointer-probe/guest/screen.ppm`);
it timed out rather than completing a reference oracle. This does not establish
a port-only incompatibility or full compiler parity. The executable owner test
uses separate declarations and commands; no compiler behavior is changed here.

## Architectural boundary

This is not a decision to move original window-manager callbacks into per-owner
tasks. Callback context is observable; the scheduled desktop must preserve the
original Fs/sys_task_being_scrn_updated contract. Nor does this prove that an
unrelated persistent worker can retain arbitrary document or callback pointers
across owner exit. That path still needs explicit lifetime protection and tests
for deletion/replacement, callback cancellation and retry before normal-boot
refresh is enabled. Root-owned graphics-storage termination is a separate gap.

The automatic A/B document-refresh gate and C1–C5 remain open. See
[the refresh integration plan](i386-document-refresh.md).

The later [managed retirement contract](i386-render-retirement.md) adds separate
independent-borrower and concurrent-deletion coverage. The linked test above
remains the regression for the original parent/child lifetime ordering.
