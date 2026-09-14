# Native bit intrinsics

The i386 backend now lowers the public HolyC `Bt`, `Bts`, `Btr`, `Btc`, `LBts`,
`LBtr`, `LBtc`, `Bsf` and `Bsr` intrinsic IDs. Standalone native sources can include
`Kernel/I386/Bits.HH` after `Kernel/Types.HH`. Full kernel sources retain the
existing KernelB declarations. These are compiler intrinsics, not separately
allocated callable function bodies.

Bit-string operations take a 32-bit pointer and a signed I64 index and return the
previous bit as a canonical Bool. The backend scales the full index before
narrowing the effective address to target pointer width. It selects a bit in the
dword at `base + 4 * floor(bit / 32)`, including negative indices and indices
outside the signed 32-bit range. Only the selected bit changes. The caller owns
a live ordinary-memory operand and must keep its entire containing dword
accessible; these primitives do not validate bounds or device memory.

The locked variants emit LOCK BTS/BTR/BTC on that dword. They preserve IF and do
not yield or call an interrupt-masking helper. Do not infer that a whole I64 or
multi-operation algorithm becomes atomic. Intel documents these locked forms,
including unaligned operands, in the [80386 manual, section 11.2](https://www.scs.stanford.edu/05au-cs240c/lab/i386/s11_02.htm).
The [BTS instruction reference](https://people.freebsd.org/~jhb/386htm/BTS.htm)
describes the containing-dword access requirement.

`Bsf` and `Bsr` scan both halves of an I64 value and return 0 through 63, or -1
for zero. The emitter tests zero explicitly before relying on the hardware scan
result and sign-extends the final result into EDX:EAX. It does not use later CPU
instructions such as TZCNT or LZCNT.

The native raw reader uses Btr on CCf_USE_LAST_U16 (bit 33), connecting this
backend support to the resident source path. The shared bitmap fixture now uses
actual Bt calls on both targets, replacing the temporary test-only word lookup.

## Verification

Run the two-generation bootstrap rebuild, followed by the lexer fixture and
standalone boot suite:

```sh
python3 tools/test-rebuild.py
python3 tools/test-i386.py --lex-state
python3 tools/build-i386-kernel.py --test
```

The common x86-64/native fixture checks signed indices -512 through 511, original
bit return values, repeated set/reset/complement operations, untouched surrounding
bytes, locked variants, unaligned bases, every single-bit I64 scan position,
512 mixed scan values with an independent shift-loop oracle, zero, side effects
and nested intrinsic calls. Native-only cases address a live stack word with
indices below -2^32 from a base 512 MiB higher and verify IF preservation with
interrupts both enabled and disabled. Bitmap classification and prior raw-input,
file-ownership and snapshot tests remain in the same suite.

Instruction audits accept the 386 bit instructions and only the emitted locked
memory forms, without allowing arbitrary LOCK-prefixed instructions. QEMU/486
execution is development evidence; strict 386SX/DX hardware/profile validation,
multiprocessor contention, full lexer tokenization and the native compiler/JIT
remain outside these tests.
