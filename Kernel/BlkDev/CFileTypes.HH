#ifndef CFILE_TYPES_INCLUDED
#define CFILE_TYPES_INCLUDED
#help_index "File/CFile"
#define FFB_NEXT_BLK		I64_MAX

#define FF_WRITE		1
#define FF_NEW_FILE		2
#define FF_BUF_DIRTY		4
#define FF_NEEDS_WRITE		8
#define FF_CONTIGUOUS		16
#define FF_USE_OLD_DATETIME	32

public class CFile //See $LK,"::/Demo/Dsk/DataBase.HC"$.
{
  I64	flags;
  CDirEntry de;
  CDrv	*dv;
  I64	fblk_num,clus,file_clus_num,max_blk;
  U8	*clus_buf;
};

#endif
