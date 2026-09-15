#ifndef I386_VGA_INCLUDED
#define I386_VGA_INCLUDED
public extern U0 I386VgaPalette(U8 *rgb6);
public extern U0 I386VgaPresent(U8 *planes);
//Scanlines in the full 153600-byte logical buffer. Invalid ranges touch no hardware.
public extern Bool I386VgaRows(U8 *planes,I64 first,I64 count);
#endif
