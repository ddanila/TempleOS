//Loaded in Adam on first use; only complete publication enables the facade.
#include "/Kernel/I386/PublicDocument.HH"
#include "/Kernel/I386/PublicLoader.HH"
#include "/Kernel/I386/JitSupport.HH"
public _extern _NATIVE_JIT_SUPPORT CI386JitSupport native_jit_support;
#define COC_LABEL_IMPL NativeSystemJITLabelFind
#define OPT_LABEL_IMPL NativeSystemJITLabelForward
#define JIT_FIXUP_IMPL NativeSystemJITFixup
#include "/Compiler/CodeLabel.HC"
#include "/Compiler/LabelForwardCore.HC"
#include "/Compiler/JITFixupCore.HC"
#define COC_LABEL_IMPL COCGoToLabelFind
#define OPT_LABEL_IMPL OptLabelFwd
#define JIT_FIXUP_IMPL CmpFixUpJITAsm
U0 NativeSystemJITPublish()
{
  U8 *s="PUBLIC JIT loaded\n";
  native_jit_support.code=&NativeSystemJITFixup;
  while(*s)OutU8(0xE9,*s++);
}
NativeSystemJITPublish;
