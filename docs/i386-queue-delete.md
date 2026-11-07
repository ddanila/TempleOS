# Public queue deletion

`QueDel` uses the unchanged original body extracted from `Kernel/KDataTypes.HC`
into `Kernel/QueueDelCore.HC`. Both x64 and the retained native console compile
that body. The native body uses the existing queue-removal intrinsic and public
heap-free service. `_QUE_DEL` is appended to the console export table; earlier
export positions stay stable. `PublicQueue.HH` wraps the intrinsic `Queue.HH`
and adds the public exported service. Internal modules can still include the
intrinsic header before console exports are available.

As on the original, `querem=FALSE` frees entries without repairing the head's
links. Callers must reinitialize that head before reusing or traversing it.
`querem=TRUE` unlinks each entry and leaves an empty circular head. Neither mode
frees the head. The contract exercises empty/nonempty queues, both modes, 256
repeated cycles per mode, adjacent data and exact data-heap recovery.

```
python3 tools/test-i386-queue-delete.py --out build/queue-original-fresh
python3 tools/test-i386-queue-delete.py build/IMAGE/kernel.img --out build/queue-native-fresh
```

The original reference passes all eight words:
`build/i386-queue-delete-original-v1/result.json`. Its complete 64-byte output
has SHA-256 `4bceb969a21579c6bc5a0fcbb54aa78d88778821db0846e1b49a71df6ed1f0f0`.
The old native image fails at the first `QueDel` use, before running the contract:
`build/i386-queue-delete-native-baseline-v1/result.json`. Both runs have an
independent terminal audit of their pinned inputs.

Two failed cross-build candidates are retained. v1 placed the console-bound
service in the intrinsic header, making internal module compilation depend on
`_QUE_DEL` too early. v2 introduced an unnecessary macro wrapper and unsupported
`#undef`. The current implementation uses the existing intrinsic directly.
Neither failed candidate qualifies any native behavior.

The final native candidate `build/i386-statement-frame-cross-v3/kernel.img`
passes all eight words and matches every original output byte in
`build/i386-queue-delete-native-v3`. The independent terminal audit confirms
unchanged inputs and exact original output equality. Runtime versions are
compiler 88 and console 248, with QueDel at appended console slot 661. This
qualifies the tested queue API behavior, not arbitrary invalid queues, concurrent
queue mutation, or complete C1–C5 compatibility.
