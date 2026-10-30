# File mask matching

`FilesFindMatch` and `WildMatch` now expose the complete original shared
implementations to native applications. The public file headers also provide
the original file-mask constants and type-filter flags. These functions were
already used internally by the native console; this change makes their actual
implementations available to guest code.

The expanded original-system fixture passes seven groups (mask 127) for case
sensitivity, basename and full-path matching, exclusion order, wildcards, all
six type filters, direct `WildMatch` calls, and caller heap recovery
(`build/files-find-match-public-original-v3`). The earlier original/shared
comparison is recorded in `build/files-find-match-original-v1` and
`build/files-find-match-shared-original-v1`.

Both original bootstrap generations and the native cross-build/386 audit pass
(`build/files-find-public-rebuild-v2.log`,
`build/i386-files-find-public-cross-v2`). The final native image also passes
the 8 MiB ordinary-include and drive-fields smoke check
(`build/files-find-match-public-smoke-8m`). The initial native comparison
`build/files-find-match-public-native-v1` timed out before its contract because
its older harness expected an obsolete startup screen; the updated runner uses
the packaged-fixture, log-driven harness. The updated native run passes all
seven groups with unchanged inputs (`build/files-find-match-public-native-v2`).

These checks do not cover every wildcard pattern, allocation failure or full
file-management workflows. The terminal right-click handler and C1–C5 remain
open.
