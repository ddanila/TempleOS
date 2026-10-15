# Formatted popup execution and buffer lifetime

Console 92 exports the original public PopUpPrint interface. The shared
Kernel/PopUpPrintCore.HC delegates all formatting to StrPrintJoin and execution
to PopUp; it preserves the original variadic source-code interface rather than
introducing an expression-only substitute. Kernel/Job.HC uses the same core.

A native common scope registers the temporary buffer before formatting. It frees
and clears that buffer on return, ordinary unwind and committed Exit. The inner
popup scope still owns the child/request; nested cleanup releases those before
the outer buffer. No public CTask layout or private service-table change occurs.
Console has 230 exports (PopUpPrint is index 229), Memory stays 25 and the private
console service table stays 48 bytes.

## Paired formatting contract

```sh
python3 tools/test-i386-popup-print-reference.py --out REF
python3 tools/test-i386-popup-print-reference.py --current-system --out SHARED
python3 tools/test-i386-popup-print.py IMAGE --out NATIVE
python3 tools/test-i386-popup-print-lifetime.py IMAGE --out LIFETIME
```

The pinned original passes six observations [1,1,1,1,1,1] in
`build/i386-c1-popup-print-float-reference/result.json`: decimal arithmetic, signed/full
64-bit results, mixed string/number/character formatting, a quoted string, floating formatted input and
repeated exact caller-heap recovery. The rebuilt original repeats the six-value
pass with the shared core in `build/i386-c4-popup-print-float-shared-reference`.
Both retain unchanged inputs.

The Console-91 native red rejects the missing PopUpPrint helper before those
cases execute (`build/i386-c2-popup-print-red/result.json`, unchanged inputs).
Console 92 passes all thirteen commands with exact Root frames and unchanged pins
in `build/i386-c2-popup-print-float-green`. The quoted source actually executes in the
servant; a matching formatted string alone is not the oracle.

## Lifetime and regression evidence

`build/i386-c2-popup-print-lifetime/result.json` passes all 24 commands with
unchanged inputs: prior-owner restoration/retirement, recovered cancellation,
committed caller kill and a recovered caller held alive until its child retires.
Mask 255 requires empty caller job rings and exact client heap before that
caller may exit. This specifically observes temporary-source reclamation that
whole-task heap teardown could otherwise hide. It also checks task retirement,
Root heap, presentation reuse and continued arithmetic.

The ordinary thirteen-command popup execution regression passes unchanged in
`build/i386-c2-popup-print-base-regression`. Original bootstrap, cross-build and
the limited 386 loader instruction audit pass in `build/i386-c2-popup-print-cross`;
all 1476 recorded source/build input hashes match. The normal 8 MiB startup gate
passes nine commands with WinMgr enabled and no build-provider loads; it takes
48.740 seconds. These are QEMU TCG 486,-fpu runs, not complete strict-386 ISA
or native-generation qualification.

The next work is the [original form/menu integration path](i386-menu-integration.md).
DocMenu/PopUpMenu/PopUpPickLst, full form input and servant presentation, GetStr,
foreign-owner/output-pointer/fault cases and complete desktop/application
qualification remain open. The 8 MiB spawned-worker capacity gap is unchanged
and is not qualified by the passing startup gate. C1–C5 remain incomplete.

The floating case formats 1.5 into `ToI64(2*(1.5000));`, executes it in the child
and requires result 3. This is an integrated software-floating input example,
not exhaustive floating formatter coverage. The earlier five-case/eleven-command
passes remain recorded separately; the final six-case checks pin the expanded
fixture and checker bytes.
