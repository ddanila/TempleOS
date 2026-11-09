# Mouse packet and wheel oracles

The packet oracle compiles arithmetic extracted from the original
`ce055f205fc38536443289fb1cfc73632f6624f4` mouse handler. It covers
10,240 complete packets: both header sign values and all 256 data bytes for
each axis and eight button combinations, plus all 256 fourth bytes for each
button combination. Native probes compile the exact current decoder source
with unbounded coordinates. These are source probes, not delivered-image IRQ
or protocol-negotiation qualification.

Evidence under `build/`:

- `mouse-packets-original-v1`: pass; independent formula audit in
  `mouse-packets-audit-v1/model.py` also passes all 10,240 original rows.
- `mouse-packets-native-before-v1`: strict failure in 6,144 cases against the
  original, with unchanged inputs.
- `mouse-packets-native-fixed-v1`: candidate decoder source passes all 10,240
  cases with unchanged inputs. Production integration is still pending.

The physical wheel fixture uses actual QEMU wheel events and a focused managed
window. It checks positive/negative public z, first-control priority outside the
control rectangle, deferred deltas under self/focus control inhibition, yielding
callback task/owner/IRQ identity, and caller/heap restoration.

- `mouse-wheel-original-v1`: fixture compilation failure from a nine-character
  exception literal; retained as failed evidence.
- `mouse-wheel-original-v2`: corrected fixture passes eight phases, six callbacks
  and mask 15 with unchanged inputs.
- `mouse-wheel-native-before-v1`: the delivered mouse-gain image completes the
  fixture but fails strict comparison: z/has_wheel remain zero and no callback
  runs. Inputs are unchanged.

Run original probes with `--out <fresh-directory>`; run native probes with
`<image> --reference <passing-original-directory> --out <fresh-directory>` using
`tools/test-i386-mouse-packets.py` or `tools/test-i386-mouse-wheel.py`.

These results do not qualify malformed streams, timing, overflow recovery,
protocol negotiation, all wheel users, callback lifetime failures, full mouse
behavior or C1–C5. The existing held-click console and unflagged DocEd failures
remain open.
