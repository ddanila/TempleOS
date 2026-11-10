# Original home-directory behavior

The original default configuration is `::/Home` (`Kernel/KCfg.HC`). Public
`Cd` without an argument, `Cd("~")`, and `FileNameAbs("~/HomeSys.HC")`
therefore resolve under `/Home`, independent of the actual boot drive.

`tools/test-i386-home-path.py` runs the same guest fixture on the pinned original
or on an input native image. It captures both Cd results, both DirCur strings,
and the expanded HomeSys path; only the actual drive letter is normalized.
Inputs are hash-pinned. The original result is:

```
1|?:/Home|?:/Home/HomeSys.HC|1|1|?:/Home
```

The native managed desktop candidate instead produces:

```
1|?:/|?:/HomeSys.HC|1|1|?:/
```

The fixture executes successfully in both systems; native fails the independent
path oracle, not parsing or startup. Evidence:
`build/home-path-original-tool-v1/result.json` (pass),
`build/home-path-native-before-tool-v1/result.json` (fail, unchanged inputs).
Earlier disposable runners preserve the same observations under
`home-path-original-v1` and `home-path-native-before-v1`.

Reproduce from the repository root with fresh output directories:

```sh
python3 tools/test-i386-home-path.py --out build/home-path-original-NEW
python3 tools/test-i386-home-path.py IMAGE --out build/home-path-native-NEW
```

The pre-repair native Kernel explicitly configures `kernel_paths.home_dir="C:/"`.
Its packaged canonical image also lacks a `/Home` directory. Correcting only a
lookup in HomeSys or adapting the oracle to root would preserve the wrong public
behavior. A repair needs the original home configuration and installed directory,
then tests for public path semantics and actual HomeSys/Once selection. HomeSet
and configurable home behavior are separate public-service gaps. Existing
configured normal-boot tests do not qualify these original default-home services.

The disposable native Kernel candidate now passes. It changes only the default
home to C:/Home and is installed onto a volume containing configured Home files.
The542593-byte emitted Kernel SHA256 is
5a8bb22ff93474d53c88ed560ee80f5da6ccaed14d2c39b66aaa6abe752abc81.
Guest linking/installation, independent486,-fpu boot/date/address/42 and unchanged
prior files pass (`home-path-candidate-queue-v1/install`). The same public path
oracle now matches the original exactly (`home-path-candidate-queue-v1/home-path`),
receipt SHA256 e9e1c7c12af53670d9b0da0c7652ad55c2b0e28aec85a55c5de8b89ce2c090f4.
The candidate delta is saved in docs/patches/i386-default-home-prototype.patch.
Production integration still needs an installed Home directory, current-source
regressions and actual HomeSys/Once selection checks. Default Once/HomeSet and
full desktop qualification remain open.

The production repair is now applied locally: Kernel defaults to C:/Home and the
image builder installs an empty Home directory in both content profiles. Fresh
classic/cross build and source/module/filesystem/386 audits pass for the first
Home epoch (`default-home-production-build-v1`), as do8MiB User255 and the public
path oracle. The configured normal desktop independently passes
`tools/test-i386-desktop-startup.py --require-home-once`: distinct Home/root
markers prove that actual HomeSys Cd/include Once selects HOME. Original83-word
geometry, actual HomeSys return, fresh42, task retirement and physical free-block
state all pass (`default-home-desktop-independent-v1`), with unchanged inputs.
The old image selects ROOT and fails this oracle with unchanged inputs
(`desktop-home-once-before-v2`). V1 is explicitly excluded because a packaging
helper changed during that run.

The first Home epoch also exposes an invalid fragmentation assumption in a
parser-memory diagnostic; see i386-parser-batch-budget.md. Its tested correction
is applied locally. A second classic/cross build and guarded production queue
are running before implementation commit. The queue includes User8MiB, home
paths, diagnostics16MiB, actual HOME Once/desktop/physical reaping, then the
existing startup workload on an independently packaged16MiB minimal-content
image at8MiB RAM, without another QEMU running. The60-second gate remains intact.
Default Once contents, HomeSet, full prompt/input/raster and whole-suite resource
qualification remain open.
