# Full content image profile

The native cross-builder has two content profiles. The default `minimal` profile
retains the existing 16 MiB behavior. `--content-profile full --disk-mib 64`
adds every path in the compatibility inventory from the current workspace,
including the bundled applications, demos, Bible and autocomplete data. It
retains the native boot area, modules and native source dependencies. The
64 MiB minimum is enforced before the build starts.

```sh
python3 tools/build-i386-kernel.py --disk-mib 64 --content-profile full --out OUT --compiler-qmp-stdio
python3 tools/test-i386-full-content.py OUT/kernel.img --out TEST_OUT
```

The image built in `build/i386-full-content-cross-v1` passes the cross-build and
386 instruction audit. An independent host read verified all 686 inventory
files against the current workspace, and the RedSea allocation bitmap matched
reachable extents. At the time of the test, 588 of those files matched the pinned
original hashes and 98 reflected current workspace changes. This is a content
manifest, not a claim that modified files match the original or that bundled
programs execute correctly. The image packages bytes; the comparison does not
establish original file attributes, timestamps, or full native installation.

The builder checks that the inventory paths match its pinned Git tree before
packaging. The validated repackage is byte-identical to the built full image
(`build/i386-full-content-repack-v2`); an incomplete inventory and an
undersized disk are rejected without writes (`build/i386-full-content-guard-v1`). `tools/test-i386-full-content-small.py`
independently rechecks every current file byte, audits the volume, and passes
native lookups for an app, demo, Bible and dictionary plus a small application
file read (`build/i386-full-content-small-v2`). The full image passed the
existing 8 MiB ordinary-include and drive-fields smoke check
(`build/i386-full-content-smoke-8m`). The first guest content check reached a
whole-Bible read but timed out at
180 seconds (`build/i386-full-content-runtime-v1`). A traced run with a
600-second command limit completed the 4,345,143-byte read and caller heap
recovery (`build/i386-full-content-runtime-v2`). This is not a startup timing
gate; large-file latency remains a performance concern. Full application, desktop,
two-generation installation and C1–C5 qualification remain open.
