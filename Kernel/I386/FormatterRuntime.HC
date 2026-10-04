//Original formatter with native flat-memory and single-CPU symbol lookup.
#include "/Kernel/StringLimits.HH"
#include "/Kernel/StrPrintTypes.HH"
#include "/Kernel/FunSegTypes.HH"
#include "/Kernel/I386/TaskHeaps.HH"
import I64 MSize(U8 *allocation);
import F64 Round(F64 value);
import F64 Floor(F64 value);
import F64 Log10(F64 value);
import F64 Pow10I64(I64 exponent);
import I64 FloorI64(I64 num,I64 to);
import U32 char_bmp_hex_numeric[16];
import U0 i386_idle();
#define SYS_IDLE_PT (&i386_idle)
extern U8 *MStrPrint(U8 *fmt,...);
extern U8 *StrPrint(U8 *dst,U8 *fmt,...);
CFunSegCache native_fun_seg_cache[FUN_SEG_CACHE_SIZE];
class CI386FunSegDebug {
  CFunSegCache *fun_seg_cache;
  I64 fun_seg_cache_index;
};
CI386FunSegDebug dbg;
F64 tS()
{
  U32 flags=I386IrqSave;
  I64 ticks=0;
  if(console_config && console_config->jiffies) ticks=*console_config->jiffies;
  I386IrqRestore(flags);
  return ToF64(ticks)/JIFFY_FREQ;
}
Bool ChkCodePtr(U8 *ptr)
{//Native memory is flat; these are the mapped boot/provider/pool regions.
  CI386Task *task=I386TaskSelf;
  CI386PublicPool *pool;
  CI386PoolRegion *region;
  CI386Heap *heap;
  U64 address=(ptr+0)(U64),base;
  if(0x11000<=address<0xA0000) return TRUE;
  if(console_config && (heap=console_config->heap)) {
    base=(heap->base+0)(U64);
    if(base<=address && address-base<heap->size) return TRUE;
  }
  if(task && task->code_heap && (pool=task->code_heap->bp))
    for(region=pool->regions;region;region=region->next) {
      base=(region->base+0)(U64);
      if(base<=address && address-base<region->size) return TRUE;
    }
  return FALSE;
}
#include "/Kernel/FunSegLookupCore.HC"
CHash *FunSegFind(U8 *addr,I64 *_offset)
{
  CHash *res=NULL;
  Bool has_lower=FALSE;
  CHashTable *h;
  CI386Task *task,*root;
  U64 best=0xFFFF;
  U32 flags=I386IrqSave;
  if(ChkCodePtr(addr)) {
    if(NativeIsDebugMode) {
      root=I386TaskSelf->owner->root; task=root;
      do {
        if(!TaskValidate(task)) goto done;
        h=task->hash_table;
        while(h) {
          HashFunSegFind(h,addr,&has_lower,&best,&res); h=h->next;
        }
        task=task->next_task;
      } while(task!=root);
    } else {
      h=Fs->hash_table;
      while(h) {
        HashFunSegFind(h,addr,&has_lower,&best,&res); h=h->next;
      }
    }
  }
done:
  *_offset=best; I386IrqRestore(flags); return res;
}
#include "/Kernel/FunSegCacheCore.HC"
#include "/Kernel/StrPrintFunSegCore.HC"
U8 *NativeFormatterFileRead(U8 *filename,I64 *_size=NULL,I64 *_attr=NULL)
{//The file service lends bootstrap-heap bytes; formatter buffers use Free.
  U8 *buffer,*result=NULL;
  I64 size=0,attr=0,exception=0;
  Bool failed=FALSE;
  if(_size) *_size=0;
  if(_attr) *_attr=0;
  if(!console_config || !console_config->files || !console_config->files->read)
    return NULL;
  buffer=(*console_config->files->read)(console_config->heap,filename,&size,&attr,NULL);
  if(!buffer) return NULL;
  try {
    result=MAlloc(size+1); MemCpy(result,buffer,size); result[size]=0;
  } catch {
    failed=TRUE; exception=Fs->except_ch; Fs->catch_except=TRUE;
  }
  I386HeapFree(console_config->heap,buffer);
  if(failed) throw(exception,TRUE);
  if(_size) *_size=size;
  if(_attr) *_attr=attr;
  return result;
}
#define FileRead NativeFormatterFileRead
#define ì (0x7FF0000000000000(F64))
#include "/Kernel/StrPrintCore.HC"
