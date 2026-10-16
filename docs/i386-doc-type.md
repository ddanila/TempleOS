# Original document output and busy delay

ConsoleRuntime 132 integrates the complete original Type, DocType, DocDump,
Busy and PortNop bodies through shared source cores. The extracted bodies match
the preceding source byte-for-byte. DocType retains text, graphics and raw-output
branches and trailing-newline behavior. Six public bindings occupy appended
indices 321–326; existing indices and data masks remain unchanged.

Native HPET reads the physical hardware counter in separate high/low/high reads,
retrying across rollover. Original Busy uses this counter when cnts.HPET_freq is
set and otherwise uses original PortNop reads of PIC port 0x21. The fixture checks
real hardware delay, zero/negative delays, PIC-mask preservation and restoration
of timer configuration/frequency. It also compiles the byte-exact Busy source,
including its original non-ASCII parameter, under a private test name. Counter
rollover itself is not exhaustively qualified.

Original, rebuilt-original and native executions pass with unchanged inputs:

- `build/i386-c2-doc-type-reference/result.json`
- `build/i386-c2-doc-type-rebuilt/result.json`
- `build/i386-c2-doc-type-native/result.json`

The native suite runs nine commands. Six saved documents cover TXT/DD/GR,
explicit/default put documents and trailing-newline counts. Invalid signatures,
unknown suffixes and missing put documents return false. The six buffers match
the original exactly, including packed graphics. Two raw captures cover direct
DocDump and raw DocType: each records cursor/geometry metadata, the full cache
and all four VGA planes. All planes equal the cache and both 192048-byte captures
match the original exactly. Four generated graphics records also have identical
hashes in both controls. The original runner at execution is archived alongside
its result; subsequent host validation additionally checks reference hashes.

The preceding Console-131 image rejects the fixture at its first Busy call
(`build/i386-c2-doc-type-native-red`). Fresh bootstrap and cross-build pass;
`build/i386-c2-doc-type-cross/input-audit.json` records all 1528 source and 24
build inputs unchanged. The isolated 8 MiB gate fails the 60-second startup limit at
62.374019 seconds in `build/i386-c2-doc-type-startup`, despite all nine behavior/
VGA checks passing, no build-provider load and unchanged execution pins. The
coordinator resumed the older C5 build and skipped dependent diagnostics.
Independent 16 MiB diagnostics pass in `build/i386-c2-doc-type-diagnostics`: all
128 push-word, 22 publication and 28 program cases, both memory phases and nine
interactive/VGA checks. Startup is 235.255434 seconds and all four execution pins
remain unchanged. This does not erase the 8 MiB timing failure.

```sh
python3 tools/test-i386-doc-type.py --out ORIGINAL
python3 tools/test-i386-doc-type.py --shared --out REBUILT
python3 tools/test-i386-doc-type.py IMAGE --reference ORIGINAL --out NATIVE
```

Original DocTermNew/UserStartUp integration and the strict TimeClock report
startup-state mismatch remain open. This checkpoint supplies Type but does not
run the original welcome sequence. All 686 inventory entries and C1–C5 remain
unqualified.
