# Storage/lexer diagnostics outside the resident kernel

`KernelStorage` mounts and reports the boot RedSea volume. Its former source
traversal test now lives in `CompilerStorageProbe.HC`, part of the temporary
extended-memory CompilerProbe module. Normal interactive boot does not load
that module. Diagnostic boot runs the check once, before the other boot-phase
compiler probes; the worker phase does not repeat the polled disk read.

The check retains its original operations and assertions:

- Read the packaged `Kernel/I386/Kernel.HC` through `I386RedSeaFileRead` with
  interrupts disabled and verify its byte count and FNV hash.
- Transfer the owned buffer into a lexer child, consume normalized characters,
  check line tracking, and resume the original empty parent at EOF.
- Verify that EOF released the source allocation, pop the parent, free the
  compiler control, and recover the original heap usage and allocation count.
- Report normalized character/line counts, their hash and transient bytes for
  independent comparison with the host's packaged source.

CompilerProbe ABI 13 extends its borrowed configuration from 56 to 68 bytes with
the mounted volume and pointers to the original resident file-read and lexer-pop
routines. Its two new imports, owned-source transfer and lexer-file push, already
exist in the resident export table. The configuration is valid only during the
synchronous call; the module retains no callback or borrowed configuration.
The diagnostic module image is still fully reclaimed after the worker probes.

The kernel suite requires the storage markers after the memory probe and before
the first compiler token probe. Version-12 rejection must occur before source
traversal, as must malformed-target and missing-import rejection. Normal boot
still checks absence of all diagnostic markers, including source traversal, and
boots successfully with an invalid diagnostic module.

Run `python3 tools/test-rebuild.py`, then
`python3 tools/build-i386-kernel.py --test`. The result records the source check's
owner as CompilerProbe and phase as boot, alongside counts, hash and reclamation.
Moving these checks changes their code placement, not the storage API or the
remaining full-OS acceptance requirements.

The resident kernel shrinks from 388912 to 383176 bytes. With the unchanged
4096-byte early stage, this leaves 5944 bytes in the 393216-byte reservation,
up from 208. Extended-memory diagnostic usage is accounted separately; the move
does not remove the code or claim a comparable reduction in diagnostic peak RAM.
The tested module uses 668824 image / 668840 heap bytes, all reclaimed after the
worker phase. Both x64 rebuild generations and the full native kernel suite pass,
including 128 console commands, startup recovery and 17 module rejections.
