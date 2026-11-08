U0 LoadOneImport(U8 **_src,U8 *module_base,I64 ld_flags)
{
  U8 *src=*_src,*st_ptr;
  I64 i,patch_address;
  U32 etype,width;
  CHashExport *tmpex=NULL;
  CHashImport *tmpiss;
  Bool first=TRUE;

  while (etype=*src++) {
    i=*src(U32 *)++;
    st_ptr=src;
    src+=StrLen(st_ptr)+1;
    if (*st_ptr) {
      if (!first) {
	*_src=st_ptr-5;
	return;
      } else {
	first=FALSE;
	if (!(tmpex=HashFind(st_ptr,
	      Fs->hash_table,HTG_ALL-HTT_IMPORT_SYS_SYM))) {
	  if (!(ld_flags & LDF_SILENT))
	    "Unresolved Reference:%s\n",st_ptr;
	  tmpiss=CAlloc(sizeof(CHashImport));
	  tmpiss->str=StrNew(st_ptr);
	  tmpiss->type=HTT_IMPORT_SYS_SYM;
	  tmpiss->module_header_entry=st_ptr-5;
	  tmpiss->module_base=module_base;
	  HashAdd(tmpiss,Fs->hash_table);
	}
      }
    }
    if (tmpex) {
      patch_address=module_base+i;
      if (tmpex->type & HTT_FUN)
	i=tmpex(CHashFun *)->exe_addr;
      else if (tmpex->type & HTT_GLBL_VAR)
	i=tmpex(CHashGlblVar *)->data_addr;
      else
	i=tmpex->val;
      if (IET_REL_I8<=etype<=IET_IMM_I64) {
        width=1; width<<=(etype-IET_REL_I8)>>1;
        //Keep address subtraction scalar-width on both x86 targets.
        if (!(etype&1)) i-=patch_address+width;
        //Both targets are little-endian; copy exactly the relocation width.
        MemCpy(patch_address,&i,width);
      }
    }
  }
  *_src=src-1;
}

U0 SysSymImportsResolve(U8 *st_ptr,I64 ld_flags)
{
  CHashImport *tmpiss;
  U8 *ptr;
  while (tmpiss=HashSingleTableFind(st_ptr,
	Fs->hash_table,HTT_IMPORT_SYS_SYM)) {
    ptr=tmpiss->module_header_entry;
    LoadOneImport(&ptr,tmpiss->module_base,ld_flags);
    tmpiss->type=HTT_INVALID;
  }
}

