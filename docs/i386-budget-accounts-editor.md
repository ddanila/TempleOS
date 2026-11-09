# Budget account-file editor

This C1/C3 component workflow drives Budget's `a` action with QEMU keyboard
input. A fixture seeds one BANK-to-RENT transaction (100.00, 09/04/1998,
`salary`); this is not evidence for entering that transaction through the form.
The observer reads documents, account state and saved files. It never invokes
an application handler to perform an edit.

The test dismisses the real instructions popup, enters the real file editor,
and uses Ctrl-T to edit its plain representation. First it changes BANK from
BLUE to GREEN and the unused CHARITY account to GHOST, then Shift-Escape
cancels. The raw draft must contain both edits, but the account file, report
and transaction must retain their original values. It opens the editor again,
changes BANK to RED and CHARITY to GIFTS, then Escape saves. The report must
turn red without changing the transaction or its identity.

The original editor returns a successful file lookup even after cancellation,
so Budget regenerates its report in both cases. The observer waits for each
regeneration and tracks the current document between phases; freed document
addresses can be reused. A cleared popup pointer alone is too early to inspect
the application result. Raw draft captures include the editor cursor marker;
the accepted raw file retains that marker too. The later Budget save emits
numeric FG tags and coalesces adjacent red BANK/CREDIT lines.

Independent host checks cover exact seed and saved account files, both raw
drafts, the intermediate accepted file, all 48 transaction bytes, all twelve
indexed strings, both reports and stable nonzero transaction identities.
Mask 1023 combines both draft observations, cancel/accept state checks and
caller restoration/readback. There is no floating-point tolerance: the seeded
100.00 record is exact on both systems.

The native test shuts down QEMU and boots the saved image again, without
installation or reseeding. A read-only Budget reopen and Shift-Escape must
produce mask 63, the same saved records and report, and unchanged file bytes,
attributes and timestamps throughout the volume. Both native console returns
must render a fresh arithmetic result 42. The original control reopens in the
same boot, not after a cold restart.

Use fresh output directories:

```
python3 tools/test-i386-budget-accounts-editor.py --archive build/i386-budget-pointer-cross-v1/exports/BudgetAccts.DD.Z --out OUT_REFERENCE
python3 tools/test-i386-budget-accounts-editor.py build/i386-popup-file-editor-cross-v2/kernel.img --reference OUT_REFERENCE --out OUT_NATIVE
```

The Budget source checker retains its existing exact sort-slot and three
pointer-width cancellation adaptations. The native regression originally stopped
before the editor phase: the standalone VGA editor lacked the original `Edit`
document identity. Caller-owned synchronous popup edits
now use the shared `DocFileEd` implementation, retaining its undo flags, directory
context, border restoration and flagged original `DocEd` session. Standalone
editing keeps its existing path. The next unchanged-fixture run reached that
editor but exposed missing Ctrl-T dispatch and standalone line navigation on
visible non-form documents. Native DocPutKey now handles the original Ctrl-T
and Shift-Ctrl-T commands and uses original boundary/cursor/line navigation for
visible WinMgr documents, while retaining the VGA editor line mover. This changes ConsoleRuntime, without changing
Budget source, compiler code or the public ABI.

Templates/periodic entries, alternate field changes,
mouse interaction, repeated-use resource profiles and complete Budget/C1–C5
qualification remain open. Component evidence does not qualify the application.

Verified controls are `build/budget-accounts-editor-original-v6/result.json`
and `build/budget-accounts-editor-native-v3/result.json`. The unchanged fixture
also retains its pre-fix and intermediate failures under native-v1 and native-v2.
`build/budget-accounts-editor-audit-v1/result.json` checks these controls, runtime
provenance, exact host oracles and deliberately corrupted records/drafts.
Both bootstrap generations pass. The standalone parent-search editor/save and
caller restoration regression passes in
`build/popup-file-editor-parent-regression-kvm-v1/result.json`; its execution
adapter supplies only KVM to the existing helper. The initial TCG attempt stops
at the startup deadline before executing that contract and remains a failed
observation. This is not low-memory, throughput or full editor qualification.
