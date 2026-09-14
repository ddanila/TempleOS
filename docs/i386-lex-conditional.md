# Native conditional preprocessing

The native dispatcher supports ifdef, ifndef, ifaot, ifjit, else and endif directives
using the real keyword registry. Symbol conditions inspect the identifier's global
hash entry with macro expansion disabled, matching the existing lexer: a matching
global symbol need not be a string macro, while a local member does not count as a
global definition. AOT/JIT selection uses CCF_AOT_COMPILE. The temporary NO_DEFINES
flag is cleared on both success and explicit native service failure.

Compiler/LexConditional.HC shares the skipped-branch traversal with the production
x64 lexer, replacing six repeated loops. It reads raw characters and invokes the
token reader only after a hash sign. Nested if/ifdef/ifndef/ifaot/ifjit keywords
increase depth; endif decreases it. The caller chooses whether an outer else ends
the skip. Return values distinguish a found delimiter (1), EOF (0) and a negative
reader/token error. Callers retain responsibility for final lookahead and replay.
The native adapter uses the existing raw-input and token services; it adds no
separate scanner or allocation ownership model.

This preserves several non-C behaviors captured from the original lexer at
f0e4307 before extraction (`build/conditional-original.log`):

- Hash signs in skipped comments or quoted text still trigger keyword scanning.
- An unmatched else skips ahead, an unmatched endif is ignored, and an unfinished
  skipped branch reaches EOF without introducing a new structural diagnostic.
- A non-identifier operand follows the original token-return behavior.
- With CCF_IN_IF set, directives return expression-boundary tokens. The existing
  ifjit path returns TK_IFAOT; the native path deliberately retains that behavior.

An active if expression still returns -4 natively unless CCF_IN_IF requests its
boundary token. The native expression parser/evaluator is not connected, so this
is not complete conditional-expression support. Other unsupported directives also
remain explicit errors. A read error does not rewind input or retain a suspended
skip continuation; callers must abort or explicitly manage recovery and cleanup.

The --lex-cond fixture shares 17 branch cases, seven expression-marker cases and
two EOF/raw-quote cases between actual x64 Lex and native dispatch. It checks
nested branches, AOT/JIT modes, global versus local symbols, value sequences,
lookahead/replay flags and owned-text reclamation. Separate tests cover raw/token
error propagation, delimiter/depth handling, name-allocation failure and an owned
include whose EOF pop is blocked by a saved lexer position. Abort cleanup must
reclaim its owned records and token text.

CompilerRuntime version 9 keeps the eight-pointer, 40-byte interface and unchanged
imports. The temporary compiler probe now selects a nested branch using the live
primitive/keyword namespace, consumes its delimiter and EOF, and reclaims token
text. The boot verifier requires CONDITIONAL PROBE records before startup and
after task/timer activity. The diagnostics module retains its existing synchronous
context and release contract.

Run:

```sh
python3 tools/test-rebuild.py
python3 tools/test-i386.py --lex-cond
python3 tools/test-i386.py --lex-define
python3 tools/test-i386.py --lex-tokens
python3 tools/build-i386-kernel.py --test
```

The native fixture uses the existing 256 KiB stage, heap at 0x60000 and CR0.EM.
General expressions, includes, executed directives, full compiler-control lifetime,
parser/JIT, DolDoc and native self-hosting remain required. QEMU/486 and executable
instruction audits do not establish strict 386SX/DX support.

Both x64 rebuild/reboot generations, the conditional fixture, definition and
mixed-token regressions, and the full kernel boot suite pass. The runtime image
is 135952 bytes with a retained 135968-byte heap span. The diagnostics image is
48232 bytes with a fully reclaimed 48248-byte span. The bootstrap stays at 372288
bytes; conditional code resides in extended-memory modules. All runtime/probe/
startup rejection, VGA/keyboard, source and timer checks continue to pass.
