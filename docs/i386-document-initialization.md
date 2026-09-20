# Native original DolDoc initialization

Current integration uses [retained document services](i386-retained-document-services.md);
the source-loading measurements below record the earlier integration stage.

Native StartOS now loads the original DocInit source,
after publishing ST_COLORS from the same color-name list used by SysDefinesLoad.
The original and native paths share the zeroed public doldoc global declaration.
This initializes document policy and dictionaries; it does not create a document,
attach an editor to the console, render document entries, or provide persistence.

DocInit publishes the original ST_DOC_CMDS, ST_DOC_FLAGS and ST_LINK_TYPES
lists using the retained public definition-list service. It creates a 512-bucket
dictionary with 43 command, 62 flag and 16 color entries, then initializes the
shared original default tables. The dictionaries and global live in the startup
task's retained scope, available to later native HolyC commands.

Dictionary construction now publishes its pointer only after completing all
insertions. A failure frees the partially populated dictionary with a dedicated
generic-entry destructor. DHT type bits overlap standard HTT source-symbol bits,
so standard HashTableDel must not be used on these dictionaries. The named
definitions are published earlier, retaining original initialization ordering;
a later failure does not roll back those definitions. Native source startup has
always documented that executed side effects are not undone by compilation
rollback. Calling DocInit repeatedly is not an idempotent reset operation.

The shared original/native check validates all 137 named definition entries,
owned index pointers, all 121 dictionary ordinals and the fixed-table fingerprint.
It also creates and destroys three temporary dictionaries, verifies unchanged
public-heap usage, and confirms the published dictionary remains available.
The native check runs through the ordinary prompt after real source startup.

## Validation and cost

Both x64 rebuild/reboot generations and the full QEMU/486 8 MiB suite pass.
The normal disk packages all 33 DolDoc source files. Interactive validation passes
172 commands / 235 lines, seven hardware breaks, eleven document-lock commands,
eight document-selection cases and exact VGA. Startup recovery and all 17 module
rejection cases pass. All 1123 OS hashes, nine build-input hashes and both disk
hashes match their manifests.

Normal startup measured 29.401 seconds, versus 16.708 seconds before loading the
document initializer and its source dependencies. Separate diagnostic startup
measured 141.982 seconds. This cost is native compilation/initialization, not a
mandatory diagnostic run. The kernel remains 363584 bytes with 25536 bytes of
reserved-load headroom. Moving stable document code into a retained module may
reduce startup cost after its dependencies are integrated; current evidence is
for real native source execution. Strict 386 and physical-hardware acceptance
remain open.
