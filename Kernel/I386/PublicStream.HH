#ifndef I386_PUBLIC_STREAM_INCLUDED
#define I386_PUBLIC_STREAM_INCLUDED
public _extern _STREAM_PRINT U0 StreamPrint(U8 *fmt,...);
public _extern _STREAM_DIR U0 StreamDir();
#define __DIR__ #exe{StreamDir;}
#endif
