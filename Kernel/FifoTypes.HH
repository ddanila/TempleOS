#ifndef FIFO_TYPES_INCLUDED
#define FIFO_TYPES_INCLUDED
#help_index "Data Types/Fifo"
public class CFifoU8
{
  U8	*buf;
  I64	mask,in_ptr,out_ptr;
};
public class CFifoI64
{
  I64	*buf;
  I64	mask,in_ptr,out_ptr;
};

#endif
