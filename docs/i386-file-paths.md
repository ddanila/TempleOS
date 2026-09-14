# Shared absolute filename and directory construction

`Kernel/BlkDev/FilePaths.HC` implements the string portion of `DirNameAbs` and
`FileNameAbs`. The x64 public wrappers retain task/drive lookup, system allocation
and FileNameAbs's optional FileFind step. Native `I386DirNameAbs` and
`I386FileNameAbs` use an explicit heap and `CFilePathContext`: current directory,
home directory, current/boot drive bytes and the original whitespace bitmap.
They perform no disk access and do not yet supply the public native file API.

## Preserved behavior

Forty-four cases passed against the original x64 functions at source revision
4e16890 before extraction. They now run against both rebuilt x64 wrappers and
native wrappers. Important distinctions include:

- Explicit `c:a` starts at `c:/a`, preserving drive-letter case. `::` selects the
  boot drive and `~:` selects the home drive, both starting at the drive root.
- A `~` directory component resets both drive and path to the home directory.
- An empty directory component resets the path to root. A trailing separator
  only produces such a component if the segment loop still has input.
- Parent components remove the last slash-delimited portion and saturate at root.
  Current/home directory strings retain their existing trailing-slash behavior.
- FileNameAbs separates the final leaf before directory normalization. Thus
  `a//b` can produce a different directory result from the directory of the
  absolute filename. Final dot, parent and home markers remain literal leaves.
- Leading/trailing whitespace and control removal follow the original three
  StrUtil flags, including whitespace control bytes, extended bytes and the
  first-byte trailing-removal quirk. The directory portion is cleaned again
  during FileNameAbs construction.
- DirNameAbs with a null or empty current directory copies the raw input without
  cleaning, normalization or a drive prefix.

Two implementation details are deliberately made safe: path segments and leaves
are copied literally instead of being passed as format strings, and an empty
directory result is checked before inspecting its last byte. A separate
percent-character fixture checks the former on x64 and i386; it is not claimed
as an original-formatting oracle.

## Storage and ownership

Shared helpers allocate nothing and consult no global task state. Inputs must be
live NUL-terminated strings. The context and its strings must remain stable;
current/boot drive bytes must be valid for the caller's drive namespace. The
whitespace bitmap must cover 256 byte values and classify NUL as non-whitespace,
as the original table does. A native home directory must have a nonempty drive
byte, a colon and a leading slash. Null/empty current directories are supported.

FilePathCapacity provides a conservative output bound from input, current and
home lengths. Writers consume mutable workspace; directory construction needs
input length plus two bytes, and filename construction needs a separate leaf
buffer of the same size. Output and work/leaf storage must be distinct and large
enough. These shared writers are internal trusted-buffer operations, not checked
parsers for arbitrary addresses.

Native wrappers reject null heap/context/name, missing bitmap/home and malformed
home prefixes. They check allocation sizes against native heap limits, allocate
workspace and output, and free workspace on every completed path. If either
allocation fails, they return null with temporary allocations reclaimed. Success
retains one independently owned NUL-terminated allocation, conservatively sized
rather than trimmed to the final string. Free it through I386HeapFree on the same
heap. Inputs are borrowed and unchanged. Allocation/free run with interrupts
masked; string processing runs with the caller's original interrupt state.
Callers must provide exclusive access to borrowed state and the heap as required
by the native allocator contract.

## Evidence and remaining integration

The `--redsea` fixture covers the 44 original compatibility cases, literal percent
text, invalid inputs, 105 heap arenas spanning initial/second-allocation failure
and success, input preservation, complete reclamation and both IF states. Its
existing RedSea/raw-read tests and whole-disk immutability check remain enabled.
The larger fixture uses a 160 KiB loader ending at 0x38000, below its heap at
0x40000. Native executable instruction audits pass; this remains QEMU/486
component evidence, not strict 386SX/DX validation.

Validation:

```
python3 tools/test-rebuild.py
python3 tools/test-i386.py --redsea
python3 tools/build-i386-kernel.py --test
```

Both x64 rebuild/reboot generations and the full standalone boot regression pass.
The standalone bootstrap remains 383496 bytes; native path services remain outside
it. Task-to-volume routing, public native FileRead and FileNameAbs flags, resident
file records, scheduler-aware disk ownership, include dispatch and compiler-control
lifecycle remain required. The helpers provide string semantics for that work;
they do not establish a resident parser/JIT, DolDoc or native self-hosting.
