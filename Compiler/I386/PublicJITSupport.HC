//Loaded in Adam on first use; only complete publication enables the facade.
#include "/Kernel/I386/PublicDocument.HH"
#include "/Kernel/I386/PublicLoader.HH"
#include "/Kernel/I386/PublicCompilerContext.HH"
#define COC_LABEL_IMPL NativeSystemJITLabelFind
#define OPT_LABEL_IMPL NativeSystemJITLabelForward
#define JIT_FIXUP_IMPL NativeSystemJITFixup
#include "/Compiler/CodeLabel.HC"
#include "/Compiler/LabelForwardCore.HC"
#include "/Compiler/JITFixupCore.HC"
#define AOT_FIXUP_IMPL NativeSystemAOTFixup
#include "/Compiler/AOTFixupCore.HC"
#define ASM_RESOLVE_IMPL NativeSystemAsmResolve
#define AOT_LOCALS_RESOLVE_IMPL NativeSystemAOTLocalsResolve
#define AOT_GLBLS_RESOLVE_IMPL NativeSystemAOTGlblsResolve
#define ASM_UNRESOLVED_ADD_IMPL NativeSystemAsmUnresolvedAdd
#include "/Compiler/AsmResolveCore.HC"
#define ASM_RESOLVE_IMPL AsmResolve
#define AOT_LOCALS_RESOLVE_IMPL AOTLocalsResolve
#define AOT_GLBLS_RESOLVE_IMPL AOTGlblsResolve
#define ASM_UNRESOLVED_ADD_IMPL AsmUnresolvedAdd
#define COC_LABEL_IMPL COCGoToLabelFind
#define OPT_LABEL_IMPL OptLabelFwd
#define JIT_FIXUP_IMPL CmpFixUpJITAsm
#define AOT_FIXUP_IMPL CmpFixUpAOTAsm
U0 NativeSystemJITPublish()
{
  U8 *s="PUBLIC JIT loaded\n";
  native_jit_support.code=&NativeSystemJITFixup;
  native_jit_support.aot_code=&NativeSystemAOTFixup;
  native_jit_support.resolve=&NativeSystemAsmResolve;
  native_jit_support.locals=&NativeSystemAOTLocalsResolve;
  native_jit_support.globals=&NativeSystemAOTGlblsResolve;
  native_jit_support.unresolved_add=&NativeSystemAsmUnresolvedAdd;
  while(*s)OutU8(0xE9,*s++);
}
NativeSystemJITPublish;
