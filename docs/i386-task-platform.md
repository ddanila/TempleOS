# Native single-CPU task platform initialization

`Kernel/I386/TaskPlatform.HH` and `TaskPlatform.HC` connect the native scheduler,
root stack/heap, task/CPU descriptors and linked context-switch entries. Link
`TaskContext.HC` with this runtime. The initializer replaces the caller's GDT and
loads FS=0x18 and GS=0x20; it assumes existing flat CS=8 and SS/DS/ES=16.

`I386TaskPlatformInit(s,root,cpu,gdt,stack,stack_size,heap)` installs once with IF
clear. The caller supplies fresh scheduler/root/CPU records, forty writable GDT
bytes, a live initialized heap, and the actual current stack extent. Storage must
be readable/writable as appropriate, disjoint and remain live. Bounds checks do
not prove mapping, allocation ownership or that an arbitrary pointer is safe.

Validation checks pointer extents, eight-byte stack alignment, size and containment
of the active frame. It rejects an existing root/owner/exception chain, an attached
CPU, an invalid heap, repeat installation or IF set before mutation. The root
receives the stack bounds and heap after scheduler initialization; the CPU receives
its self pointer and scheduler. The runtime builds and loads the GDT and installs
the scheduler binding callback, immediately binding root. Unexpected failures after
validated initialization begins halt with IF clear rather than returning a partially
installed platform.

Before each switch, the binding callback requires IF clear and verifies that the
task belongs to this scheduler and is its selected current task. It rewrites the
FS descriptor and calls the linked segment-reload entry. GS continues to name the
single CPU record. Scheduler code owns interrupt masking and switch ordering.
This supplies the existing cooperative model; it does not add preemption or
multicore behavior.

Root stack registration enables bounded Caller diagnostics and task-owned exception
records on the root task. The heap must outlive those records and all users. No
teardown or reinitialization is provided. NMI-safe transitions, public CTask/CPU
migration and complete boot/device/interrupt ordering remain unfinished.

The exception-task fixture uses this initializer, checks root FS/GS and stack/heap
binding, handles an exception on root, then runs two heap-owned workers through
creation/destruction cycles and catch-time switches. Its final restoration of the
runner's hardware descriptors is test cleanup, not a runtime teardown API.

The exception-task fixture passes rejected/repeated initialization checks, root
stack/heap/FS/GS identity, root exception diagnostics and reclamation, plus all
48 worker catch-time yields with CPU identity checks. Native instruction audits,
the general task regression and both x86-64 rebuild/reboot generations pass.
