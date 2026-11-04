# Autocomplete suggestions and Ctrl+F1

The rebuilt original and native normal image pass a real source-suggestion
interaction. The unchanged MakeAC library traverses a project file through
ACInit, loads all 95,293 dictionary words, and starts its actual task. Real
keyboard input types ACUI; Ctrl+F1 completes ACUIAlpha through the application's
ACFillIn, In, input-filter jobs and public key messages. Semicolon/Enter executes
the completed function exactly once and the console visibly displays 42.

Evidence:

- Original: `build/i386-autocomplete-interaction-reference-v7/result.json`.
- Native: `build/i386-autocomplete-interaction-native-v5/result.json`.
- Native image: `build/i386-autocomplete-interaction-cross-v1/kernel.img`.

The native run uses 64 MiB, KVM and `486,-fpu`, with live WinMgr and welcome
content. It loads the actual library, project and observer through AdamFile;
application bodies, source statistics, dictionary, completion and input services
are not replaced. The observer never invokes completion or executes the chosen
function. The host presses the actual Ctrl/F1 keys and then submits the result.
The test harness and both guest fixture sources are archived beside each run.
All pinned inputs remain unchanged. Offline file extraction and the filesystem
extent/bitmap audit run after QEMU closes. Both persisted native reports match
the copies exported from guest memory.

An independent host oracle tokenizes the entire project: eleven distinct words,
including ACUIAlpha thirteen times, ACUIAlpine nine times and ACUIAlto five times.
It also walks the pinned word list and independently computes hash bucket and
insertion order for zero-hit dictionary matches. The five expected suggestions
are those three project symbols followed by ACUITY and ACUITION. Names, order,
hit counts, current prefix, partial length and both word counts are checked.
This is a project-file statistics workflow, not installed-tree traversal.

The serialized widget document matches the original, normalizing only the
fixture's C:/ versus T:/ project path. Its geometry is exactly columns 51-78 and
rows 13-28. All 28,672 pixels of that 224x128 viewport match the original, including
colors, underlined source links and numeric dictionary choices. Window borders,
variable task titles and surrounding terminals are outside that comparison.
The visible result check requires the exact 42 font bitmap on white with one
uniform foreground color and records that color; it does not qualify complete
terminal appearance. The selected input report is exactly `SELECTED ACUIAlpha`.

The initial native image found the same five suggestions but ignored Ctrl+F1.
The console only consumed character key-downs, so the function key never reached
DocPutKey. The delivered console now sends Ctrl+F1 through Ctrl+F10 and Ctrl+digit
key-downs to DocPutKey. The original symbol and word action branches are shared
in `DocAutoCompleteActionCore.HC`, retaining their distinct lock ordering, enable
result, shift alternatives, index conversion and Fs parent. Callbacks bind native
resident document code to the real loaded functions through CallExtStr. Key
descriptions remain in the original caller so KeyDescSet still sees that caller.
Expanding the shared calls restores the complete preceding DocPutKey source;
both extracted action bodies match after callback-name/whitespace normalization
(`original-action-retention.json` beside the image). The original interaction
also passes after extraction. This does not retain every original DocPutKey
branch on native.

The observer waits for the application's post-refresh sleep, then requires the
serialized document and geometry to remain unchanged across a new WinMgr frame.
The prefix pointer is assigned before scanning/printing and is not a readiness
fence. Requiring the application to remain asleep after that frame was also an
invalid fence: native frame progress could extend past its 333 ms sleep. The
stable-frame check retains exact document and pixel comparisons. DocSave can
recalculate and remove temporary save cursors; snapshots use the same real API
on both systems.

The first original attempt had an uninitialized execution counter; the project
now initializes it explicitly. A black-only result pixel check rejected the
original's blue output; the final check records the foreground and compares the
exact glyph mask. Native attempts v2/v3 stopped at the observer's invalid fence,
not at a completion action. Native v4 passed the interaction; v5 additionally
archives input sources and closes the guest before disk checks. A cold-key check's
first screenshot preceded the console refresh; the final check waits for the
actual answer pixels.

The separate cold-start check passes without loading autocomplete
(`build/i386-autocomplete-cold-keys-native-v3/result.json`): real Ctrl+F1 and
Ctrl+1 consume their shortcuts without changing 6*7, which then executes and
visibly displays 42. The reusable cold-key tool first asserts that AutoComplete
is absent from the real task hash chain and audits the final filesystem offline. The 8 MiB normal-startup smoke passes in 42.66 seconds with
live WinMgr/welcome, public input state/timing and exact framebuffer checkpoints
(`build/i386-autocomplete-interaction-minimal8-v1/result.json`). Neither is the
complete minimal suite. Both original rebuild generations, the 386 instruction
audit and all 1,261 delivered-source checks pass.

Other symbol indexes and modifiers, actual numeric-word selection, source and
definition popups, the custom editor's shortcut routing, default autoload,
installed-tree statistics, exact application heap recovery and full desktop/
minimal-profile/release qualification remain open. C1-C5 remain open.


With the qualified original rebuild and word archive from
[the asset workflow](i386-autocomplete-assets.md) available, use fresh output
directories:

```sh
python3 tools/test-i386-autocomplete-interaction.py --out build/ac-ui-reference
python3 tools/test-i386-autocomplete-interaction.py build/i386-autocomplete-interaction-cross-v1/kernel.img --reference build/ac-ui-reference --out build/ac-ui-native
python3 tools/test-i386-autocomplete-cold-keys.py build/i386-autocomplete-interaction-cross-v1/kernel.img --out build/ac-ui-cold
```
