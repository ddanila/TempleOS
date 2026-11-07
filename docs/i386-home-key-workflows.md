# Default Home keyboard workflows

HomeKeyPlugIns.HC is a separate stage before DolDoc key dispatch. Its unchanged
pinned original source installs MyPutKey/MyPutS with priority 0x20000000 and
metadata support. The plugin consumes the listed Alt inputs when Ctrl is absent;
unhandled keys and all PutS calls pass onward. A direct DocPutKey test therefore
cannot qualify the default physical-key behavior for these combinations.

The following is a source-derived C1 workflow map, not runtime qualification.
Every action needs its exact description-only counterpart, modifier guards,
consumption/fallthrough observation, caller restoration and resource recovery.

| Input | Original action | Required independent observation |
| --- | --- | --- |
| Alt-F1 / Shift-Alt-F1 | Insert PURPLE / LTPURPLE | Exact DolDoc colour entries and foreground raster; unchanged text/search state |
| Alt-F2 / Shift-Alt-F2 | Insert RED / LTRED | Exact colour entries and foreground raster |
| Alt-F3 / Shift-Alt-F3 | Insert GREEN / LTGREEN | Exact colour entries and foreground raster; demonstrate that the F3 search handler is not called |
| Alt-F4 / Shift-Alt-F4 | Insert BLUE / default FG | Exact colour entries/raster; no file picker |
| Alt-F7 | Insert inverse date/time text using Now | Entry structure, date/time format and bounded clock observation |
| Shift-Alt-F7 | Consume without action or description | No mutation and no downstream handler invocation |
| Alt-a / Alt-A | Enable / disable autocomplete | Actual task/widget lifecycle, prior state and cleanup |
| Alt-h / Alt-v | Tile windows horizontally / vertically | All affected window geometry, focus/order, borders and framebuffer |
| Alt-m | Enable border then maximize | Geometry changes in correct order, title/border/client rendering |
| Alt-l | Replace clipboard with link to current document line; special Bible verse branch | Exact FL or BF link, canonical filename or verse, line mapping, clipboard lifetime |
| Alt-L | Insert an anchor and put its link on clipboard | Matching random anchor identity in both document and FA link; handle nondeterminism explicitly |
| Alt-1/2/3/4 | Insert original bytes E3/E9/E8/EA | Exact byte/entry/cursor and font glyph rendering |
| Alt-9 / Alt-0 | Insert ID +5 / -5 indentation commands | Exact entries, resulting layout and cursor |
| Ctrl-Alt, unhandled Alt inputs and PutS | Return FALSE to continue the chain | Correct downstream handler, no plugin side effects |

The original run `build/i386-doc-find-editor-original-v1` reached eight physical
find-key receipts, then physical Alt-F3 did not reach the document callback.
Its retained `guest/final.png` visibly shows green text. This agrees with the
source's earlier MyPutKey interception. The test was deliberately stopped after
identifying its incorrect expectation that Alt-F3 was an editor no-op. It does
not export the inserted colour entry or establish full colour-workflow cleanup;
its `terminal-audit.json` records the bounded observation. No native counterpart
or complete action/metadata oracle exists for these Home workflows yet.

The corrected [find-key comparison](i386-doc-find-keys.md) exercises physical
F3/Shift-F3 separately and retains Alt suppression as a direct DocPutKey API
contract. These are distinct requirements. Home startup/plugin installation and
the default physical-key pipeline remain required C1/C2 work; this source audit
leaves the inventory item unqualified.
