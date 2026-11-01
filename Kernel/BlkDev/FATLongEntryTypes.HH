#ifndef FAT_LONG_ENTRY_TYPES_INCLUDED
#define FAT_LONG_ENTRY_TYPES_INCLUDED
class CFAT32DirEntryLong
{
  U8	ord;
  U16	name1[5];
  U8	attr,
	type,
	xsum;
  U16	name2[6],
	zero,
	name3[2];
};

#endif
