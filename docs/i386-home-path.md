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

The current native Kernel explicitly configures `kernel_paths.home_dir="C:/"`.
Its packaged canonical image also lacks a `/Home` directory. Correcting only a
lookup in HomeSys or adapting the oracle to root would preserve the wrong public
behavior. A repair needs the original home configuration and installed directory,
then tests for public path semantics and actual HomeSys/Once selection. HomeSet
and configurable home behavior are separate public-service gaps. Existing
configured normal-boot tests do not qualify these original default-home services.
