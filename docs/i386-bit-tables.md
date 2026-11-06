# Public byte lookup tables

Psalmody's original `GodWordStr` provider is defined in `Adam/God/HolySpirit.HC`.
Loading that source currently rejects `rev_bits_table` in `GodHexIns`, before
reaching `GodWordStr`. The public original kernel declares both
`U8 *rev_bits_table` and `U8 *set_bits_table` in `Kernel/KernelC.HH`.

`tools/test-i386-bit-tables.py` reads all 256 values of both public tables from
an unmodified original runtime. The host independently calculates byte reversal
using binary-string reversal and population counts using `int.bit_count`.
The test exports the complete arrays, checks every byte, and preserves its
fixture, runner, logs and input hashes. Native success also requires fresh
rendered arithmetic after the fixture.

* `build/i386-bit-tables-original-v1/result.json`: passes both complete arrays;
  all inputs unchanged.
* `build/i386-bit-tables-native-v1/result.json`: fails when compiling the fixture
  at `rev_bits_table`, line 6; all inputs unchanged. No native table check ran.

```
python3 tools/test-i386-bit-tables.py --out build/bit-tables-original
python3 tools/test-i386-bit-tables.py build/IMAGE/kernel.img \
  --out build/bit-tables-native
```

The existing native `RawOutputRuntime.HC` owns a 256-byte reversal array initialized
by `NativeRawInit`, but only exposes it through a compile-time macro to the raw
renderer. It does not provide the original public pointer variable. Integration
must preserve that shared backing and add the population-count table, expose
pointer storage with the correct data-export metadata, and declare the original
public pointer types. Exporting the byte-array address as though it were pointer
storage would be an ABI error. The active nine-module build pins these core
sources; the implementation change follows its terminal input audit.

This checks public table values, not table reassignment, all consumers, the full
God provider or Psalmody workflow. C1–C5 remain incomplete.
