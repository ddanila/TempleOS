#ifndef DIR_ENTRY_TYPES_INCLUDED
#define DIR_ENTRY_TYPES_INCLUDED
#include "/Kernel/DateTypes.HH"
#define CDIR_FILENAME_LEN	38 //Must include terminator zero
public class CDirEntry
{
  CDirEntry *next,*parent,*sub;
  U8	*full_name;
  I64	user_data,user_data2;

  U0	start;
  U16	attr;
  U8	name[CDIR_FILENAME_LEN];
  I64	clus,size;
  CDate datetime;
};
#define CDIR_SIZE (sizeof(CDirEntry)-offset(CDirEntry.start))

#endif
