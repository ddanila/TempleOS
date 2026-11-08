# Output-window exhaustion at the 8 MiB compiler frontier

At commit `188eba0378b32d6d452e4372a362d12317314f73` (compiler ABI 100),
the unchanged 24-case public lexer contract still fails while compiling
`C:/Compiler/I386/PublicLexNumber.HC`. A hardware breakpoint at entry to
`I386ParserFailure`, conditional on the `EMIT` label prefix, captured physical
memory before the failure logger or exception cleanup ran. GDB detached after
capture and the guest produced the expected output-window rejection. The driver,
GDB commands/log, input image, guest log, result and complete 8 MiB snapshot are
preserved in `build/i386-window-heap-capture-v1`; the driver itself is
`build/capture-window-heap.py`.

The captured runtime module hash is
`cfe84a0cf6156463a154a651eb6a6dbc59c6c36df44a166d3603a761d0d1103b`.
The physical snapshot SHA-256 is
`de85bf895d5bc6915c24fbf53572bef78270bed4cfa51fc821618ab6ac98edf3`.

Reproduce the offline census with:

```sh
python3 tools/audit-i386-heap-snapshot.py \
  build/i386-window-heap-capture-v1/physical.bin \
  --heap 0x102530 --output-owner 0x771e48 \
  --report build/i386-window-heap-capture-v1/census.json
```

The tool uses ABI-100 32-bit pointer layouts with 64-bit I64 fields. It walks
all bootstrap heap blocks, checks bounds/alignment/tags, reconciles used spans
and allocation counts with the heap descriptor, checks the current control's
bidirectional ownership queue, and validates the output chunk chain and capacity.
Optional repeated `--task-heap` arguments now validate nested native cached
spans and page accounting; see [cached-page reclamation](i386-cached-page-reclamation.md).
The tool does not interpret every live public task-heap object or prove allocator
correctness generally.

| Measurement at rejection | Bytes/count |
| --- | ---: |
| Bootstrap heap capacity | 6,754,304 bytes |
| Used spans | 6,753,776 bytes |
| Live bootstrap allocations | 20,393 |
| Total free spans, including headers | 528 bytes |
| Largest free span, including header | 32 bytes |
| Free blocks | 20 |
| Output count and capacity | 3,320 bytes |
| Planned complete output | 7,245 bytes |
| Raw output chunks | 33 |
| Current control live IR nodes | 1,384 |
| Current control IR requested payload, each | 128 bytes |
| Current control IR occupied span, total | 199,296 bytes |

The current control also owns one 85-byte segmented-output header, 17 backend
workspace allocations (nine 68-byte fixups, seven 44-byte records and one 52-byte
call context), two 48-byte saved headers and 59 76-byte miscellaneous records.
These are requested payload sizes; bootstrap block headers/alignment add space.

This is actual arena exhaustion at the captured point, not just a large
contiguous request missing otherwise abundant free space. The adaptive emitter
has consumed progressively smaller holes down to four-byte windows. Backend
workspace reuse removed the earlier call-context failure but cannot alone supply
the missing output and eventual executable copy. Current live IR occupies much
more than backend scratch. Large bootstrap allocations also include public pool
backing regions; their nested live/cached contents need a separate census before
claiming those bytes are reclaimable. The next implementation should reduce a
measured live resource cost, preserving grammar, ownership and failure recovery.

This capture adds diagnostic evidence only. The lexer API was not published;
8 MiB normal compiler delivery, the remaining workflows and full C1–C5 gates
remain open. Qualification stays 2/686.
