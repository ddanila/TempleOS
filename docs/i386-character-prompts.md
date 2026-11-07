# Public character and confirmation input

Console interface 228 exposes the original `GetChar`, `YorN`, `AreYouSure`
and `PressAKey` functions. Their bodies are moved unchanged into shared cores
used by both the original kernel and native console. Public argument defaults,
zero-character filtering, optional echo and confirmation text are preserved.
This supplies the confirmation dependency of the still-missing `Fmt` used by
FileMgr; it does not qualify FileMgr or its directory picker.

`tools/test-i386-character-prompts.py` runs the same guest fixture on the pinned
original or a supplied native image. Twelve independent boolean results cover
zero-character and key-up filtering, returned scan code, default/disabled echo,
ignored non-answer input, affirmative and negative confirmation, PressAKey text
and exact task heap recovery. `--hardware` additionally injects F1 and then `a`
through QEMU while GetChar waits, checks that F1 does not complete the call,
and verifies ASCII 97, scan code 30 and clearing of the task idle flag.
The native run concludes with exact rendered `6*7` result pixels.

Evidence:

* `build/i386-character-prompts-source-parity.json`: all four function bodies
  match their original source bytes.
* `build/rebuild-character-prompts-v1-verified/result.json`: both original
  bootstrap generations pass.
* `build/i386-character-prompts-cross-v1/post-export-source-audit.json`: all
  1,729 production source hashes match the bootstrap after native exports.
* `build/i386-character-prompts-original-hardware-v1/result.json`: all twelve
  queued checks and the hardware table pass; execution inputs are unchanged.

* `build/i386-character-prompts-native-hardware-v1/result.json`: all twelve
  queued checks, hardware table and concluding arithmetic pixels pass at
  64 MiB with KVM. Terminal audit independently verifies both tables, exact
  original/native equality and every input hash.

The earlier native interface-227 baseline rejects the missing GetChar before
executing assertions. Original fixture v1 incorrectly omitted the required
DocRst argument; its compiler-error screenshot and explicitly stopped run are
preserved. Corrected queued original v2 passes. Each run preserves its fixture
and runner; those earlier frozen versions predate the hardware extension.

Raw/debug cursor input, interrupt/recovery combinations, complete FileMgr and
C1–C5 remain unqualified. Full diagnostic and interactive cross-build checks
are tracked separately from this direct API comparison.
