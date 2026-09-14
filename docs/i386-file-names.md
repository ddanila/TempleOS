# Shared filename extensions and compression suffixes

`Kernel/BlkDev/FileNames.HC` contains the original extension-dot scan and shared
suffix/default-extension/toggled-Z writers. The x64 DskStrA entry points use these
helpers, and `Kernel/I386/FileNames.HC` supplies owned native `I386ExtDft` and
`I386ToggleZorNotZ` results through an explicit heap. These are filename-string
operations; they perform no disk I/O or path resolution.

Compatibility includes behavior that differs from typical modern path libraries:

- FileExtDot scans the entire path. It skips a dot followed by slash or another
  dot; it does not restart the scan at directory boundaries.
- A dot in a directory can therefore suppress the default extension.
- IsDotZ and IsDotC require more than one dot anywhere in the string and a terminal
  uppercase .Z or .C. A single-extension Test.Z toggles to Test.Z.Z.
- No-extension names receive a literal dot followed by the supplied extension.
  An empty extension adds a trailing dot; whitespace and drive text are preserved.

Shared writers require live NUL-terminated inputs and sufficient distinct output
storage. Native wrappers reject null inputs/heap, return null on allocation
failure and return independently owned results on success. They allocate exactly
the output byte count including NUL. Callers free results with I386HeapFree.
Allocation runs with interrupts masked and restores the caller's IF state before
copying; borrowed input strings and the heap remain exclusively owned/live.
The existing x64 wrappers retain their system allocator and public signatures.

Before extraction, 21 default/toggle/dot/suffix cases and five contiguous-suffix
checks passed against the original x64 public functions at 51be92f. The same
fixture executes against the rebuilt x64 functions and native wrappers. Native
coverage additionally exercises null inputs, 32 exhausted heap arenas with both
operations, unchanged input storage, exact allocation sizes, reclamation and IF
preservation. The expanded RedSea fixture retains its 128 KiB loader and separate
heap, existing path/file-read/partial-I/O tests and unchanged whole-disk check.

Validation commands:

```
python3 tools/test-rebuild.py
python3 tools/test-i386.py --redsea
python3 tools/build-i386-kernel.py --test
```

The native filename helpers are available for file/include integration. They are
not yet linked into the standalone bootstrap or compiler runtime. Absolute path
construction, task current-directory/drive rules, .Z lookup fallback, parent
search, resident-file records, decompression and include dispatch still require
integration. Keeping those semantics explicit avoids mistaking volume lookup for
the full public FileRead contract.
