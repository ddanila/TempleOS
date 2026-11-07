# Public member and metadata lookup

Normal Console 247 publishes MemberFind, MemberMetaData and MemberMetaFind using
the complete unchanged Compiler/MemberLookup.HC bodies. Exports 658–660 append
these functions; existing slots and the 21-word data-export bitmap are unchanged.
Compiler runtime 85 and the Console service layout remain unchanged. The strict
builder requires all three real functions.

Run tools/test-i386-member-lookup.py --out OUT for the original, or supply a native
image before --out. Original-v2 and normal native-v2 match mask 4095: empty/missing
lookups, both search branches, inheritance, derived shadowing, exact use counts,
U32 wrap without adjacent corruption, full-width metadata, zero versus absence,
string/F64 values, duplicate first-match order and exact data/code heap recovery.
The previous native image rejects the first MemberFind call before behavior.
MemberFind alone increments the selected member's U32 use count; metadata lookup
preserves the records. Inputs must be stable live trees/lists with valid links.
Invalid/cyclic metadata and concurrent mutation remain unqualified.

The normal compiler's existing metadata format is compatible with these bodies:
the complete unchanged Demo/ClassMeta.HC now runs through ExeFile and matches the
original in all three complete output documents. See docs/i386-class-meta.md.
The source compiler probe also uses the normal public functions; only its private
MemberClassBaseFind helper remains source-loaded. No replacement public lookup
implementation is injected into that probe.

Both x86-64 bootstrap generations and the full native build pass all 1759 source
pins and 386 instruction auditing. These rebuilds do not prove binary identity
or C5 native generations. Evidence: build/i386-member-lookup-{original,baseline,native}-v2, build/i386-member-class-meta-initial-audit.json and
build/i386-member-lookup-cross-v2/source-body-abi-audit.json. Full public compiler,
API/workflow coverage and C1–C5 qualification remain open.

The internal MemberLookup.HH now reuses native public declarations when the
public document/compiler header is present. Its former plain forward declarations
shadowed all three resolved functions with the undefined-extern address. A
focused --header probe records addresses before/after the include: the old header
changes all three; the guarded header preserves all three exactly. The initial
source compiler run had passed earlier regressions but failed shared class
parsing with UndefExt. That failure is retained in
build/i386-member-lookup-functions-native-v1 and the focused before/after records
are in build/i386-member-header-binding-{baseline-v2,native-v1}.

The final source integration run passes all twenty-three stages and every prior
token/graph/expression/type/runtime/lifetime/class/function check with exact
original function bytes and both heap recoveries. The 1032-input audit proves
that no public lookup body is injected. Both 8/16 MiB profiles match all 307200
welcome pixels, and the 16 MiB diagnostic completes both program, code-ownership
and file-cleanup phases. Evidence: build/i386-member-lookup-functions-native-v2/
terminal-integration-audit.json and build/i386-member-lookup-memory-audit-v2.json.
