#ifndef I386_PUBLIC_FILES_INCLUDED
#define I386_PUBLIC_FILES_INCLUDED
public _extern _DIR_MK Bool DirMk(U8 *filename,I64 entry_cnt=0);
public _extern _DIR I64 Dir(U8 *filename=NULL);
public _extern _ED_DIR Bool EdDir(U8 *directory=NULL);
public _extern _FILE_DEL Bool FileDel(U8 *filename);
public _extern _FILE_RENAME Bool FileRename(U8 *old_filename,U8 *new_filename);
public _extern _DIR_DEL Bool DirDel(U8 *filename);
public _extern _FILE_MOVE Bool FileMove(U8 *old_filename,U8 *new_filename);
#endif
