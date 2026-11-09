# Quoted document source entries

The unchanged MsgLoop investigation found a missing `msg_code` header link.
`tools/test-i386-document-literal.py` isolates the problem from rendering,
message delivery and document insertion: it compiles an actual included source
file, calls its two string-returning functions, and exports the exact returned
bytes, including the NUL terminator.

The link case uses MsgLoop's `LK,"msg_code",A="MN:MSG_CMD"` command inside a
quoted literal. The ordinary-text control uses `TX+UL,"underlined"`.
The independent expected bytes require the link command to survive and the
ordinary underlined text to become its tag. The original deliberately excludes
ordinary text styling from dollar reconstruction; serializing every text entry
would be an incorrect repair.

The initial reference prototype wrongly expected the text control to retain its
underline command. Its failure is retained at `build/document-literal-original-v1`.
The corrected original contract passes at `build/document-literal-original-v2`.
Both actual outputs match the corrected literal expectations. The fixture source
was unchanged; the driver expectation was corrected from observed original
behavior and the original lexer rules.

The full ABI268 candidate at `build/i386-keyboard-mouse-scan-cross-v1/kernel.img`
fails at `build/document-literal-native-before-v1`: the link case returns
`Use  defines.` instead of the complete original link literal. The text control
correctly returns `Use underlined text.`. Inputs remain unchanged. No native
pass or application qualification is claimed.

`Compiler/I386/LexInput.HC` reconstructs a selected set of formatting entries in
quotes, but skips link entries. The original `LexDollar` uses `Doc2PlainText`
and quoted dollar escaping for entries selected by `LexGetChar`; it also has
special rules for ordinary text, markers, cursors, binary entries and shifted
script. The next repair must preserve those decisions, work with document roots
and included documents, and maintain compiler allocation/snapshot lifetimes.
The original serializer already exists in `Adam/DolDoc/DocPlainTextCore.HC`;
a shared provider is preferable to another incomplete serializer in the lexer.

This is a strict failing C3 regression, not a change to source syntax or an
application-specific workaround. It covers two entry cases, not every DolDoc
command, ownership path or complete MsgLoop/C1–C5 acceptance. Qualification
remains 2/686.
