#ifndef I386_FILE_CONTEXT_INCLUDED
#define I386_FILE_CONTEXT_INCLUDED
#include "/Kernel/I386/FilePaths.HH"
#include "/Kernel/I386/FileLoad.HH"
#include "/Kernel/BlkDev/DriveTypes.HH"
//Borrowed mounted volumes, indexed by uppercase drive letter minus A.
class CI386ResidentFile {
  CI386ResidentFile *next;
  CI386Heap *heap;
  U8 *name,*data;
  I64 size;
};
class CI386FileVolumes {
  CI386RedSea *letter[26]; CI386ResidentFile *resident; CI386Heap *resident_heap;
  //Stable public identities share the lifetime of the mounted-volume table.
  CDrv drives[26];
};
//Quiescent volumes/channel and IF clear. Paths/volumes stay stable throughout the call.
//Owned decoded bytes; optional owned name is the requested absolute name, not a found alias.
//Failure leaves all optional outputs unchanged. This is not the public FileRead API.
public extern U8 *I386FileReadAt(CI386Heap *heap,CFilePathContext *paths,
  CI386FileVolumes *volumes,U8 *filename,I64 *size=0,I64 *attr=0,U8 **name=0,
  Bool require_session=FALSE,Bool raw=FALSE,Bool stored=FALSE);
#endif
