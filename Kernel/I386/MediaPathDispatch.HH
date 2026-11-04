#ifndef I386_MEDIA_PATH_DISPATCH_INCLUDED
#define I386_MEDIA_PATH_DISPATCH_INCLUDED
extern Bool NativeFileUsesOriginal(U8 *path);
extern U8 *NativeOriginalFileRead(U8 *filename,I64 *_size=0,I64 *_attr=0);
extern I64 NativeOriginalFileWrite(U8 *filename,U8 *buffer,I64 size,CDate datetime=0,I64 attr=0);
extern Bool NativeOriginalFileFind(U8 *filename,CDirEntry *entry=0,I64 flags=0);
extern Bool NativeOriginalCd(U8 *dirname=0,Bool make_dirs=FALSE);
extern Bool NativeOriginalDirMk(U8 *filename,I64 entry_cnt=0);
extern I64 NativeOriginalDir(U8 *mask,Bool full);
#endif
