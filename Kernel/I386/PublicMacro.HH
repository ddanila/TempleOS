#ifndef I386_PUBLIC_MACRO_INCLUDED
#define I386_PUBLIC_MACRO_INCLUDED
public _extern _SYS_MACRO_2_STR U8 *SysMacro2Str(CJob *macro_head);
public _extern _SYS_MACRO_STRIP_KEY U0 SysMacroStripKey(CJob *macro_head,I64 arg1,I64 arg2);
public _extern _PLAY_SYS_MACRO U0 PlaySysMacro(I64 n=1);
#endif
