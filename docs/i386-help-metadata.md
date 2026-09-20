# Native help-file metadata

Native command input now accepts the original `#help_file` directive. It adds
an `HTT_HELP_FILE | HTF_PUBLIC` source symbol, with the current help index and
source link, to the input's private symbol table. The normal queue header again
uses `#help_file "::/Doc/Que"` directly.

The retained file service applies the existing `ExtDft(name,"DD.Z")` and
`FileNameAbs` semantics using a borrowed snapshot of the current task's file
context. Explicit extensions remain unchanged, `::` selects the boot drive, and
relative paths use the task's current directory. Resolving help metadata does
not read the referenced file or require it to exist.

The resolver returns one allocation from the compiler's heap. `I386ParserTake`
registers that allocation with the current control; failure leaves ownership
with the caller, which frees it before throwing OutMem. The symbol, help index
and source link use the existing parser allocation tracking. A failed input
reclaims them without publishing help entries. Successful publication transfers
the complete graph to the task; the shared symbol visitor handles destruction.

Repeated help-file directives are legal. Publication preserves newest-first
lookup within one input and across later inputs, without weakening duplicate
checks for ordinary declarations. Source links preserve the original lexer's
lookahead behavior: a directive on line four followed by a newline records line
five. The same input in `Kernel/I386/HelpFileCheck.HH` is checked against the
original x64 lexer and the native compiler, including the help index and link.

Boot and worker public-header probes cover repeated directives, explicit and
default extensions, source metadata, failed-input rollback, include-guard retry
and complete reclamation. Normal startup loads the actual queue help directive.
The lower-level lexer requires a parser directive callback; the retained command
input supplies the file-service binding used by this implementation.

FileRuntime is version 20 with a 36-byte service table. CompilerRuntime 42,
CompilerProbe 12 and ConsoleRuntime 8 identify the corresponding consumers.
Public document records, document services and the integrated DolDoc editor
remain separate integration requirements. This change supplies metadata; it
does not implement the interactive help browser.
