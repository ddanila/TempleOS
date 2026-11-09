# Native packet decoding and wheel dispatch

The native decoder uses the packet header sign bits for the full signed movement
range, rather than sign-extending each data byte. It assembles three- or
four-byte packets without writing beyond `bytes[3]`. The device state remains
40 bytes: protocol size, capability flags and the fourth byte occupy its former
trailing padding. Compile-time assertions retain the count/installed offsets.

Boot setup disables keyboard traffic during exclusive controller access,
negotiates the original 200/100/80 sample-rate sequence, queries the device type,
queries again after sample rate 10, and restores resolution/scaling/rate before
enabling streaming. Keyboard re-enabling runs on failure paths too. Console ABI
265 rejects pairing the new stream producer with an older Console consumer.

The IRQ observer accumulates integer wheel deltas and stores cumulative z beside
each raw queue slot. Scheduled processing applies the existing scale/grid math,
updates public mouse state and publishes logical 3D queue metadata. The extra
native `MouseGet` API retains raw x/y and its existing button interface.

The managed WinMgr dispatches pending wheel deltas to the first wheel callback
of the focused window under the pointer, without requiring a hit inside the
control rectangle. Self/focus control inhibition retains pending deltas; the
idle pump can deliver them after inhibition clears. Callbacks use the existing
owner-borrowing and cancellation scopes. The consumed-z baseline resets on a new
worker, as in the original WinMgr task. Retained legacy view input paths remain
outside this dispatch scope.

## Evidence

`build/i386-mouse-wheel-cross-v1` is the full-profile 64 MiB image built after
two source-matching classic bootstrap generations. Kernel is 457416 bytes;
Kernel and ConsoleRuntime are the only changed compared module outputs against
`i386-mouse-gain-cross-v3`. The builder's 386 instruction audit passes. These
classic bootstrap generations are not C5 native self-hosting generations.

- `mouse-wheel-packets-v1`: all 10240 source-decoder probe rows exactly match
  `mouse-packets-original-v1`; independent original arithmetic model passes.
- `mouse-wheel-native-v1`: physical wheel state/callbacks exactly match
  `mouse-wheel-original-v2` across eight phases, six callbacks, mask 15.
- `mouse-wheel-audit-v1`: independently accumulated wheel model matches both
  runs and rejects 172 single-value corruptions. The host module validator
  accepts ABI 265 and rejects a mutation to 264; this is not a live mismatch boot.
- `mouse-wheel-queue-v1`: queue mask 1023 and initial raw/logical 320,240.
- `mouse-wheel-gain-v1`: all 62 original physical-input phases/744 values match.
- `mouse-wheel-lifetime-v1` and `mouse-wheel-click-lifetime-v1`: five modes each
  pass 255, covering throw, recovering/committed Exit and owner retirement.

These passing native runs preserve fixture files/metadata and execute a fresh
42 afterward. Input hashes remain unchanged. Original and strict old-native
failures are preserved as described in [the oracle record](i386-mouse-packet-wheel-oracles.md).

Malformed/resynchronized packets, controller failures on physical hardware,
Explorer device negotiation, complete extra-button APIs, queue burst/FIFO parity,
speed/timestamp parity, retained legacy views, every wheel consumer and complete
window/raster/resource behavior remain unqualified. The existing held-click
console and unflagged DocEd failures remain open. This is partial C2/C4 progress,
not complete mouse or C1–C5 qualification.
