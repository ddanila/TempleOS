# Original TimeClock punch-command contracts

`tools/test-i386-timeclock-punch-reference.py` restores the pinned original tree
and repaired assets using the same provenance as the existing
[storage/report oracle](i386-application-matrix.md). The application Load,
Install and TimeClk sources are unchanged. The test fixture uses the original
`In` input queue and real `GetStr`; it does not replace the app's input, clock,
reporting or storage functions.

```sh
python3 tools/test-i386-timeclock-punch-reference.py --out OUT
```

The first capture passes in `build/i386-c3-timeclock-punch-reference`, with
unchanged fixture/tool inputs. The fixture initializes an empty application
file, then calls the public commands in this order:

| Action | Persisted observation |
| --- | --- |
| PunchOut while already out | Empty file remains an EOF byte |
| PunchIn with multiline description and Escape | IN record with `alpha\nbeta\n` |
| PunchIn while already in | Exact saved bytes unchanged |
| PunchOut with description and Escape | OUT record with `finish\n` |
| PunchOut while already out | Exact saved bytes unchanged |
| PunchIn with text followed by cancel | IN record with an empty description |
| PunchOut with immediate Escape | OUT record with an empty description |

Cancelling description input does **not** cancel the punch: the original command
substitutes an empty string and commits the record. This is an application
contract to preserve, even if a different UI convention seems preferable.

The host independently decodes the saved byte stream as a one-byte record type,
little-endian 64-bit date, NUL-terminated description, and final EOF byte. It
checks all four final records, every intermediate file prefix, exact duplicate
file identity, and the absence of trailing data. Each stored date must lie
between original `Now` readings immediately around its command. The first
capture has equal date ticks for all four records; this is not evidence for
elapsed-time accounting across a clock transition. The final original
`TimeRep` must report a closed session.

This adds command/input/storage integration beyond the earlier test that
constructs entries directly. It does not prove physical keyboard handling,
reboot persistence, report formatting for these new records, time progression,
resource cleanup or complete TimeClock compatibility. Native Load and the same
punch workflows still require qualification; the native GetStr dependency
remains under development.


The native equivalent now passes ten first-boot commands and four cold-reboot
checks in build/i386-c3-timeclock-punch-reopen-result with unchanged inputs.
All four records, descriptions, timestamp bounds, intermediate prefixes and
duplicate-file identities match the original oracle, and the reopened logical
file is byte-identical. The application source remains unchanged. See
[i386-timeclock-native.md](i386-timeclock-native.md), including the separate
strict report failure caused by missing original welcome-document state.
