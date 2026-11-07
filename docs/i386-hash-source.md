# Public symbol source metadata

The original token lexer calls `HashSrcFileSet` when publishing definitions and
help-file symbols. The native public chain lacked this dependency. Console 236
now exports its unchanged original body through `Kernel/HashSourceCore.HC`, also
included by the original `Kernel/KHashB.HC`. The public signature retains the
optional line adjustment and its zero default.

The function replaces the symbol's source link with `FL:filename,line`, clamps
adjusted lines to at least one, adds the private flag when requested, and replaces
its copied help index. Turning off the compiler option does not clear a private
flag already on the symbol. An empty or null current help index yields a null
symbol index. Existing source/index allocations are freed before replacement.

`tools/test-i386-hash-source.py` resolves the actual function through its public
hash record and checks eight bits, yielding mask 255:

- Exact initial and adjusted source links, including the lower line clamp.
- A copied help index with independent allocation, then empty/null handling.
- Private-flag insertion, retention after disabling the option, and preservation
  of unrelated symbol flags.
- Replacement of an existing source filename and preservation of the control's
  buffer and position.
- Thirty-two replacements without heap growth and exact caller heap recovery
  after freeing the symbol fields and compiler control.

## Evidence

- `build/i386-hash-source-original-v2`: original mask 255, with exact restored
  reference and execution-input audit.
- `build/i386-hash-source-native-baseline-v2`: missing public symbol on the
  preceding reader image, before behavioral checks. Independent audit confirms
  successful normal startup, unchanged execution inputs and boot area, all
  original file tuples, and the sole exact fixture addition.
- `build/i386-hash-source-native-v1`: mask 255 and arithmetic pass on the fresh
  `i386-hash-source-cross-v1` image.
- `build/i386-public-lex-char-source-v1`: the original 26-character/eight-state
  prompt and reader contract also passes on that image.

V1 of the fixture used nonexistent `OPTF_KEEP_PRIVATE` rather than the original
bit index `OPTf_KEEP_PRIVATE`. Native compilation rejected it; the original run
was explicitly canceled with SIGINT after that known fixture defect was found.
Neither v1 run is behavioral evidence. V2 uses `Bts`/`Btr` on the original index.
`build/i386-hash-source-parity.json` verifies the entire shared production body
against the pre-change source.

Run into fresh output directories:

```sh
python3 tools/test-i386-hash-source.py --out build/hash-source-original-new
python3 tools/test-i386-hash-source.py build/i386-hash-source-cross-v1/kernel.img --out build/hash-source-native-new
```

This contract uses a standalone source-symbol record. It does not qualify
publication through the token lexer, concurrent mutation, allocation-failure
recovery, source navigation, or complete hash/compiler behavior. Public token
lexing still needs its diagnostics, expression and executable-directive services;
no substitute implementations are supplied here. All C1–C5 milestones remain
open.

## Build and regression audit

The final image SHA-256 is
`16275fce0f770f1ed872b0589d424947d129c8cced9f376bac24d9cf2a1ea629`.
Both bootstrap generations and the fresh full cross-build pass. All 1,749
production-source hashes and sixteen module hashes match; the kernel is 419,896
bytes. The final source-metadata and reader tests have independent terminal
audits covering every execution input, original file tuple, exact fixture
addition, boot area and filesystem allocation.

Normal 8 MiB startup and 16 MiB diagnostics both pass all 307,200 welcome pixels.
Diagnostics complete both program, code-heap ownership and file-break cleanup
phases, and both images finish shared startup without source errors or rejected
input. `final-contract-audit.json` in the cross-build directory checks these
results and unchanged source-image hashes together. Concurrent tests do not
qualify isolated startup timing or installed native generations.
