I64 HashEntrySize(CHashSrcSym *tmph)
{//Logical size of a std system hash entry.
  CDbgInfo *dbg_info;
  CBinFile *bfh;
  switch (HashTypeNum(tmph)) {
    case HTt_DEFINE_STR:
      return MSize(tmph(CHashDefineStr *)->data);
    case HTt_GLBL_VAR:
    case HTt_CLASS:
    case HTt_INTERNAL_TYPE:
      return tmph(CHashClass *)->size;
    case HTt_FUN:
      if (dbg_info=tmph->dbg_info)
	return dbg_info->body[dbg_info->max_line+1-dbg_info->min_line]
	      -dbg_info->body[0];
      else
	return -1;
    case HTt_FILE:
      return MSize(tmph(CHashGeneric *)->user_data0);
    case HTt_MODULE:
      if (StrCmp(tmph->str,KERNEL_MODULE_NAME))
	return MSize(tmph(CHashGeneric *)->user_data0);
      else {
	bfh=mem_boot_base-sizeof(CBinFile);
	return bfh->file_size;
      }
    case HTt_WORD:
      return StrLen(tmph->str);
  }
  return -1;
}

#include "/Compiler/HashMemorySizeCore.HC"

#include "/Compiler/MapFileWriteCore.HC"
