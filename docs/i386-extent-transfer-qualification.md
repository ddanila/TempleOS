# i386 extent-transfer qualification

The unpromoted integrated candidate moves regular files between directories by
publishing the existing data extent, unlinking the old name, and clearing a
versioned transfer journal. This avoids allocating another contiguous copy of a
large native module. Current main OS filesystem services remain ABI 40; the
candidate is preserved in `patches/i386-memory-baseline-integrated-candidate.patch`.

## Verified outcomes

| Gate | Evidence | Outcome |
| --- | --- | --- |
| Actual native installation fragmentation | `build/fragmented-module-move-green/result.json` | PASS: 1,154,987-byte native ConsoleRuntime retains its extent; exact namespace and filesystem ownership checked. |
| Only one free sector | `build/low-space-move-bounded-writes/result.json` | PASS: large module moves out and back with 512 bytes maximum free extent. Final disk bytes outside the two directories unchanged. This is not a trace of transient writes. |
| Every prepared move write/flush failure | `build/extended-transfer-io-matrix-four/result.json` | PASS: four writes and four flushes, each armed independently, followed by recovery boot and complete-file/journal/bitmap checks. |
| Interrupted destination expansion | `build/move-growth-failures/result.json` | PASS: nine write and eight flush failures; every armed failure fires, reboot recovery retains one complete moved file and all five existing files, with journal/ownership/bitmap checks and unchanged source inputs. |
| Destination directory expansion | `build/move-directory-growth-full-sector/result.json` | PASS: a full 512-byte directory grows to 1,024 bytes on a fresh extent; moved data extent 19839 and metadata remain unchanged; five existing files and moved payload match exactly. Writable read-only reboot preserves the disk hash. |

The eight recovery cases preserve exactly one name with the complete `IO`
payload. Write failures 1–3 retain the source; write failure 4 retains the
destination. Flush failures 1–2 retain the source; flush failures 3–4 retain the
destination. Each recovered volume has 873 files and 17,782 owned sectors, with
its bitmap matching unique reachable extents and no remaining move journal.

These results cover different immutable candidate images. They do not qualify a
later source revision automatically. The growth test uses the corrected native
TEST candidate; the combined memory-baseline candidate still needs its full
suite and native installation generations.

## Reproduction

Use a fresh output directory for each command. The retained source below must
first pass the six-module native build; its `/Probe` module outputs are the
fragmentation fixture inputs.

```sh
python3 tools/test-i386-fragmented-module-move.py \
  build/extended-transfer-native-build/source.img --out build/move-fragmented-new
python3 tools/test-i386-move-directory-growth.py \
  build/extended-top-test-fix/build/top-test-kernel/kernel.img \
  --out build/move-growth-new
```

The growth fixture requests five user entries with `DirMk`, which adds three
bookkeeping entries before sector rounding. It fills all five available slots
before moving a sixth file. Public `FileWrite` success is a positive block
number; the test independently checks stored contents rather than interpreting
that return value as a byte count.

The full candidate `tools/build-i386-kernel.py --test` runs the prepared move
failure matrix with updated payload checksums. Its legacy copy-based seven-write
and six-flush limits have been replaced by the transfer path's four writes and
four flushes. The old failure at position five remains preserved as evidence
that no fifth write occurred.

## Open qualification

The interrupted-growth matrix now passes on its dedicated fixture source; it
does not automatically qualify later revisions or additional child-directory
reparenting configurations. Complete
current-source workstation acceptance, two native generations, resource budgets,
386 executable audits and release publication remain open. Physical hardware
and manual sessions remain deferred.
