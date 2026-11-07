# Shared class and function-header parser execution

The --classes mode of tools/test-i386-public-expression-source.py now executes
the actual shared PrsClass and PrsFunJoin bodies after publishing twenty-one
source stages. It uses an isolated owned hash table with the normal task table
as a borrowed parent. No replacement class/header implementation is injected.

Eight native observations pass: entry availability, packed eleven-byte class
layout, I64 member metadata, a three-byte array with evaluated bound/dimension
metadata, class persistence after controller release, two function arguments with
a default value of seven and target-width frame offsets, function persistence
after controller release, and exact recovery of both current-task heaps after
deleting the owned metadata table. The fixture calls the functions through their
actual published addresses. Normal source delivery still lacks the complete
public compiler; these are diagnostic source-loaded execution results.

The original reference uses normal ExePutS compilation because its private parser
entry points are not visible through the public hash namespace. All seven
metadata observations agree, using sixteen/twenty-four-byte argument offsets on
x86-64 versus eight/sixteen on i386. The original retains 6488 bytes in its shared
data/code heap after both symbols are deleted. This baseline resource behavior
is recorded explicitly and is not an allowance for native cleanup: native still
requires exact recovery. Earlier original probes that required complete heap
recovery remain failed evidence. The initial private-parser lookup attempt also
remains a failed visibility diagnostic.

All earlier lexer, graph, basic expression, type, runtime-call/storage and
retained-code/unresolved-function-completion regressions pass in the same native
guest, followed by normal arithmetic output and fixture-only volume validation.
The first twenty-stage class publication baseline failed at missing public
HashSingleTableFind; normal startup now supplies that binding.

Function bodies, global declarations through this complete source pipeline,
assembly/stream/AOT integration, repeated or mismatched headers, inheritance,
error/unwind paths, normal public compiler delivery and full C1–C5 qualification
remain open. No inventory entry is qualified by this narrow execution probe.

Evidence: build/i386-public-classes-source-native-v3/result.json and its
terminal-integration-audit.json; build/i386-public-classes-original-v4/result.json.
The native audit checks all 1029 inputs at terminal completion and retains the
reference-only fixture before its later resource-record extension. Native
packaged fixtures, compiler bodies and image remain unchanged.
