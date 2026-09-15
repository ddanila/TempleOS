# Native publication of opaque class dependencies

Native command publication accepts ordinary forward class declarations such as
`extern class Opaque;`. The class descriptor, pointer variants, name and source
metadata transfer from the compiler control to the task's symbol scope. The
declaration does not allocate executable storage or an instance of the class.

An unfinished class must still have the shape of an empty forward declaration:
zero size, offset and member count, no members, base class or forwarding alias,
and the initialized empty member-list tail. Import and unresolved-symbol flags
are rejected. The usual publication ownership and collision checks apply.

Published globals, function results and members may refer to an incomplete class
through pointers. Publication rejects direct value types and base classes that
are still incomplete. Numeric forwarding aliases retain their existing behavior;
pointer depth is checked independently of raw type. This does not add a new
layout for an opaque class or invent the fields of public kernel records.

For example, these separate console submissions now retain a usable record:

```c
extern class Opaque;class Holder{Opaque *p;I64 value;};
sizeof(Holder); //12: a four-byte pointer and an eight-byte integer
Holder h;h.p=0;h.value=42;
h.value;
```

The shared parser can complete a private forward declaration within the same
input. A record parsed before that definition retains the same class identity:

```c
extern class Node;class Link{Node *p;};class Node{I64 value;Link link;};
```

Completing an ordinary forward declaration published by an earlier input now
uses a [private completion transaction](i386-class-completion.md). The owning task
parses against a private definition and commits its members into the stable public
descriptor only after the whole input passes publication checks. Failed parsing,
abandoned controls and failed publication preserve the old layout and pointer
identities. Completing a declaration inherited from another task's scope remains
rejected because its metadata belongs to that task's lifetime and heap.

Top-level class and extern-class statements use the same type-service class
callback as nested declarations. The native callback stages published completions;
the host callback continues to use the original shared class parser.

`CompilerOpaqueProbe.HC` exercises seven cases on boot and worker tasks: ordinary
publication, three malformed-descriptor mutations with successful retry after
restoration, incomplete value/base rejection, and completion of mutually linked
private classes. It checks pointer identity, use from fresh controls, rollback after a later syntax error in a completion input, and exact reclamation of heap/control/task state. The
keyboard suite independently checks the example above through VGA output.

Verification commands:

```sh
python3 tools/test-rebuild.py
python3 tools/build-i386-kernel.py --test
```

See [PLAN.md](../PLAN.md) for public task/CPU migration, the complete document
workflow, self-hosting, memory targets and strict 386 acceptance requirements.
