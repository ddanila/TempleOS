# Lexer snapshot pop validation candidate

`I386LexPop` validates the head snapshot, then validates each remaining
snapshot under the same interrupt exclusion before restoring or detaching.
Previously it validated the head and then called the pin scan, which validated
the same head again; its computed pin result was not used. Later pin scans
that determine whether detached files may be released remain unchanged. Each
snapshot validation still performs its complete heap and ownership checks.

Both original rebuild generations pass (`build/rebuild-test`). The native
lexer-state and snapshot-boundary tests pass, including rejected corrupted
tail snapshots and later heap corruption; the cross-build and 386 audit pass
with 1545 source and 24 build inputs unchanged (`build/i386-lex-pop-tail-cross`).
Isolated startup and 16 MiB diagnostic gates remain pending. This is a
performance candidate, not evidence of a measured speedup or C1–C5 completion.
