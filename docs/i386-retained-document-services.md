# Retained native document services

ConsoleRuntime 15 contains the original document
initialization, dictionary, allocation/copy/size and form-navigation functions.
The original globals and initializer are split into reusable bodies and tiny
source-time invocation files; x64 still invokes them in its original order.
Native StartOS now loads public declarations and calls ConsoleDocumentStart
instead of compiling these document bodies on every boot.

The console module imports eleven existing public memory/hash functions. Kernel
binding resolves their retained export names and supplies the original function
names expected by the shared sources. The loader validates the complete import
contract and console version before callbacks run. The shared document functions
and global are checked as native module exports by the image builder.

The module owns the doldoc record and code. The live console task owns dictionary
and definition storage through its public heap. Initialization occurs in that
task after public-header loading. Repeating ConsoleDocumentStart for the same
task preserves the initialized state; a different task cannot take over the
initialized service. This follows the retained console's existing single-owner
lifetime. It is not a general multi-terminal document-owner teardown facility.
As before, original DocInit/DocGlobalsInit themselves are not transactional reset
APIs, and previously published definitions are not rolled back after a later
initialization failure.

The existing original/native dictionary, defaults, entry-copy and form-navigation
corpora now exercise retained native bindings. The prompt test additionally calls
the startup wrapper twice and checks unchanged dictionary identity and heap usage.
The instruction audit admits the 386 INC instruction used by retained StrLen
lowering; it retains the existing instruction classification and module checks.

The editor goal still requires original document lifecycle, reporting,
recalculation, rendering, editor callbacks and the persistent edit/execute/reboot
workflow. Retaining these prerequisites controls startup compilation cost while
those dependencies are integrated; it does not complete that workflow.

## Validation and measured cost

Both x64 rebuild/reboot generations and the full native QEMU/486 8 MiB suite
pass. Native module export validation covers all 13 document functions and the
doldoc global. The existing dictionary, defaults, allocation and form corpora pass
through the retained bindings, along with repeat initialization. The prompt suite
passes 178 commands / 241 lines, seven hardware breaks, eleven document-lock
commands, eight document-selection cases and exact VGA. Startup recovery and all
17 incompatible-module rejection checks pass. All 1130 source hashes, nine build
inputs and both disk hashes match.

Normal startup measured 19.067 seconds, down from 41.141 seconds. Separate
diagnostic startup measured 132.162 seconds. ConsoleRuntime 15 is 117144 bytes
and retains 117160 bytes. The kernel is 364664 bytes, leaving 24456 bytes after
the 4096-byte early stage in its 393216-byte reservation. Service/config record
sizes remain 32/28 bytes. The preview is the validated normal disk. These are
QEMU/486 measurements; strict 386 and physical-PC acceptance remain outstanding.
