#include "/Kernel/I386/Scheduler.HH"
I64 um_values[24];
U0 UMLog(U8 *s){while(*s)OutU8(0xE9,*s++);}
U0 UMProbe()
{
  CI386Task *native=Fs;
  CI386Heap *heap=native->memory;
  CTask *task;
  I64 i,mask=0,used,allocations;
  U8 *s;
  if(!heap || heap->signature!=I386_HEAP_MAGIC || heap->size<1048576)throw('UMHeap',TRUE);
  for(i=0;i<2;i++){task=User;Kill(task);WinFocus(Fs);Sleep(100);}
  for(i=0;i<3;i++) {
    used=heap->used;allocations=heap->allocations;
    task=User;
    um_values[i*8]=used;um_values[i*8+1]=allocations;
    um_values[i*8+2]=heap->used;um_values[i*8+3]=heap->allocations;
    if(Kill(task))mask|=1<<(i*2);
    WinFocus(Fs);Sleep(100);
    um_values[i*8+4]=heap->used;um_values[i*8+5]=heap->allocations;
    um_values[i*8+6]=Fs->data_heap->used_u8s;um_values[i*8+7]=Fs->code_heap->used_u8s;
    if(heap->used==used && heap->allocations==allocations)mask|=2<<(i*2);
  }
  s=MStrPrint("EXPORT user-main-heap.bin %X %X\n",um_values,sizeof(um_values));UMLog(s);Free(s);
  s=MStrPrint("USER MAIN HEAP MASK %d\n",mask);UMLog(s);Free(s);UMLog("USER MAIN HEAP DONE\n");
}
