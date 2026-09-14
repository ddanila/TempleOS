#ifndef FILE_NAMES_INCLUDED
#define FILE_NAMES_INCLUDED
public extern U8 *FileExtDot(U8 *src);
public extern Bool IsDotZ(U8 *filename);
public extern Bool IsDotC(U8 *filename);
public extern I64 FileNameLength(U8 *name);
//Borrowed NUL-terminated inputs; caller supplies sufficient distinct output storage.
public extern U8 *FileNameWriteDefault(U8 *dst,U8 *name,U8 *extension);
public extern U8 *FileNameWriteToggle(U8 *dst,U8 *name);
#endif
