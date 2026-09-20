#ifndef KERNEL_DEFINE_TYPES_INCLUDED
#define KERNEL_DEFINE_TYPES_INCLUDED
#include "/Kernel/HashTypes.HH"
extern class CAOTImportExport;
class CDbgInfo
{
  U32	min_line,max_line;
  U32	body[1]; //Code heap is 32-bit value
};

public class CHashSrcSym:CHash
{
  U8	*src_link,
	*idx;
  CDbgInfo *dbg_info;
  U8	*import_name;
  CAOTImportExport *ie_lst;
};

public class CHashDefineStr:CHashSrcSym
{
  U8	*data,**sub_idx;
  I64	cnt;
};

#endif
