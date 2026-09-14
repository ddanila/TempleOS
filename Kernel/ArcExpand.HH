#ifndef ARC_EXPAND_INCLUDED
#define ARC_EXPAND_INCLUDED
#include "/Kernel/Arc.HH"
//Trusted initialized codec state and well-formed input. Buffers and stack stay borrowed.
//Read supplies the next code without advancing src_pos, or a negative service error.
//False leaves partial output/state; caller must discard/reset after a reader error.
public extern Bool ArcExpandStep(CArcCtrl *c,I64 (*read)(CArcCtrl *c),U0 (*entry)(CArcCtrl *c));
#endif
