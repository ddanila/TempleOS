# Native include-directive dispatch

`I386LexNextWithIncludes` accepts a borrowed `CI386LexIncludeService` alongside
its existing heap, compiler control, punctuation tables, macro filename and line
counter. The service supplies a context pointer and a synchronous push callback.
The lexer carries this binding through recursive token reads and conditional
scanning. It has no direct disk or current-task dependency.

For an active include directive, the lexer reads the filename token using the
same dispatcher, so macro-expanded and recursively produced filenames work. A
string invokes the provider, then lexing continues from the published child.
The include stack preserves parent lookahead and reclaims owned children at EOF.
A non-string token follows the original Lex finish/replay behavior. Semicolons
remain ordinary tokens after child input returns.

The provider receives a borrowed filename from the current token. It must copy
that name before retaining it or changing token storage. Success must publish an
owned child on the supplied compiler control. Failure must preserve input state
at callback entry and reclaim temporary allocations. The lexer returns -1 on
provider failure; it does not roll back the tokens already consumed to reach the
callback. The filename token remains available for diagnostics. Token-reading
errors propagate without invoking the provider.

A null service or push callback returns -4 when an active include is encountered.
The original five-argument I386LexNext remains a wrapper without an include
provider, preserving its callers and the retained module's existing interface.
KEEP_SIGN_NUM still returns the literal marker without dispatch. Well-formed
includes in inactive conditional branches do not invoke the loader. Conditional
scanning continues to use the original raw-marker rules, including their known
behavior inside strings/comments.

## File provider and lifetime

`I386LexFileInclude` adapts a borrowed `CI386LexFileContext` containing paths and
volume bindings to the existing I386LexIncludeFile bridge. It supplies the default
extension, both original normalization steps, decoded disk bytes, copied source
name and owned include publication described in `i386-file-context.md`.
Its quiescent-volume, exclusive-channel and IF-clear requirements still apply.
The callback interface itself adds no interrupt masking or scheduling policy.

Keep the service, context, tables, heap and referenced code alive and stable for
each dispatcher call, including its recursive calls. Loaded file records and
source bytes then follow their separate include-stack ownership. A callback from
a module also requires that module to remain loaded while calls can use it.

## Evidence and integration scope

The expanded `--lex-cond` suite runs eight scenarios against the original x64
Lex reading real fixture files, then against native dispatch with an owned-buffer
provider. The host checks that those files exactly match the native provider's
source text. Cases cover nested files, macro filenames, definitions created by
children, semicolon replay, empty files, inactive nested conditionals, recursive
filename production and non-string arguments. Native callback counts prove which
loads occur; final heap checks cover token strings, definitions and child records.

Additional native cases verify provider failure with an unchanged callback-entry
compiler snapshot and heap baseline, continued parent input, both unavailable
provider forms, character-token errors and KEEP_SIGN_NUM. Existing conditional
compatibility and failure tests remain enabled.

The `--redsea-read` suite now calls the actual disk provider through the same
callback signature. Its two-volume routing, nested plain/compressed raw input,
partial-I/O failures and 86 constrained-heap cases pass. This separately verifies
the disk adapter; a combined retained-lexer/disk command still needs integration.

Validation commands:

```
python3 tools/test-rebuild.py
python3 tools/test-i386.py --lex-cond
python3 tools/test-i386.py --redsea-read
python3 tools/build-i386-kernel.py --test
```

Both x64 rebuild/reboot generations, native suites, instruction audits and full
standalone boot checks pass. The standalone bootstrap remains 383496 bytes.
The retained compiler image is now 138168 bytes (138184 heap bytes), an increase
of 2216 bytes. Its version-9, eight-entry service table still calls the providerless
entry; publishing an include-capable resident service and binding file services
remain required work. Task-aware disk ownership, public errors and resident-file
semantics, full compiler-context lifetime, parser/JIT, DolDoc, strict 386 profiles
and self-hosting are still open.
