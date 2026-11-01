#ifndef FAT_ENTRY_TYPES_INCLUDED
#define FAT_ENTRY_TYPES_INCLUDED
class CFAT32DirEntry
{
  U8	name[11],
	attr,
	NTres,
	CrtTimeTenth;
  U16	CrtTime,
	CrtDate,
	LstAccDate,
	clus_hi,
	WrtTime,
	WrtDate,
	clus_lo;
  U32	size;
};

#endif
