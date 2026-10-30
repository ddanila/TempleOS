#ifndef I386_PROGRESS_TYPES_INCLUDED
#define I386_PROGRESS_TYPES_INCLUDED
//Original CProgress layout and fixed array dimensions.
#define PROGRESS_BARS_NUM 4
#define PROGRESS_DESC_LEN (64-8-8)
public class CProgress {
  I64 val,max;
  F64 t0,tf;
  U8 desc[PROGRESS_DESC_LEN];
};
#endif
