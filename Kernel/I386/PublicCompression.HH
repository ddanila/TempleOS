#ifndef I386_PUBLIC_COMPRESSION_INCLUDED
#define I386_PUBLIC_COMPRESSION_INCLUDED
#include "/Kernel/Arc.HH"
public _extern _EXPAND_BUF U8 *ExpandBuf(CArcCompress *arc,CTask *mem_task=NULL);
public _extern _COMPRESS_BUF CArcCompress *CompressBuf(U8 *src,I64 size,CTask *mem_task=NULL);
public _extern _ARC_COMPRESS_BUF U0 ArcCompressBuf(CArcCtrl *c);
public _extern _ARC_CTRL_DEL U0 ArcCtrlDel(CArcCtrl *c);
public _extern _ARC_CTRL_NEW CArcCtrl *ArcCtrlNew(Bool expand,I64 compression_type=CT_8_BIT);
public _extern _ARC_EXPAND_BUF U0 ArcExpandBuf(CArcCtrl *c);
public _extern _ARC_FINISH_COMPRESSION Bool ArcFinishCompression(CArcCtrl *c);
#endif
