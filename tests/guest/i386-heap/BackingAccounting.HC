#include "/Kernel/I386/BackingCheck.HC"
CI386BackingPool accounting_pool;
CI386Heap accounting_heap;
CHeapCtrl accounting_control;
I64 BackingAccountingTest()
{//Live payloads must recover exactly even when their heap retains page cache.
  CI386BackingPool *pool=&accounting_pool;
  CI386Heap *heap=&accounting_heap;
  CHeapCtrl *control=&accounting_control;
  CI386BackingCheck check;
  CI386Heap private_heap;
  U8 *private_live;
  U8 *permanent,*temporary,*leak;
  I64 i,retained,count,span;
  U64 before;
  U32 flags=GetRFlags;
  if(!I386HeapInit(heap,0x40000,196608) || !I386MemBackingInit(pool,heap,8192) ||
      !I386MemHeapInit(control,pool)) return 481;
  permanent=I386MemAlloc(control,40000);
  if(!permanent) return 482;
  for(i=0;i<40000;i++) permanent[i]=i+23;
  if(!I386BackingCheckSave(&check,heap,control)) return 483;
  retained=pool->retained; count=pool->owned_count;
  temporary=I386MemAlloc(control,160);
  if(!temporary || !I386MemFree(temporary) || pool->retained<=retained ||
      pool->owned_count!=count+1 || !I386BackingCheckRestored(&check)) return 484;
  //The same baseline must reject both public and physical payload leaks.
  leak=I386HeapAlloc(heap,64);
  if(!leak || I386BackingCheckRestored(&check) || !I386HeapFree(heap,leak) ||
      !I386BackingCheckRestored(&check)) return 485;
  leak=I386MemAlloc(control,64);
  if(!leak || I386BackingCheckRestored(&check) || !I386MemFree(leak) ||
      !I386BackingCheckRestored(&check)) return 486;
  //Malformed accounting must fail without repairing or changing owned bytes.
  pool->retained++; before=Hash(heap->base,heap->size);
  if(I386BackingCheckRestored(&check) || Hash(heap->base,heap->size)!=before) return 487;
  pool->retained--;
  span=pool->owned->span; pool->owned->span+=8; before=Hash(heap->base,heap->size);
  if(I386BackingCheckRestored(&check) || Hash(heap->base,heap->size)!=before) return 488;
  pool->owned->span=span; pool->owned_count--;
  if(I386BackingCheckRestored(&check)) return 489;
  pool->owned_count++;
  if(!I386BackingCheckRestored(&check)) return 490;
  before=Hash(&check,sizeof(CI386BackingCheck));
  if(I386BackingCheckSave(&check,heap,0) ||
      Hash(&check,sizeof(CI386BackingCheck))!=before) return 491;
  for(i=0;i<40000;i++) if(permanent[i]!=(i+23)(U8)) return 492;
  if(!I386MemFree(permanent) || !I386MemHeapDestroy(control) ||
      !I386MemBackingDestroy(pool) || heap->used || heap->allocations ||
      !I386HeapValid(heap) || (GetRFlags^flags)&0x200) return 493;
  //A diagnostic worker can have a private compiler arena while its public
  //allocations grow from a different physical backing heap.
  if(!I386HeapInit(&private_heap,0x80000,32768) ||
      !I386MemBackingInit(pool,heap,8192) || !I386MemHeapInit(control,pool)) return 494;
  permanent=I386MemAlloc(control,40000); private_live=I386HeapAlloc(&private_heap,64);
  if(!permanent || !private_live) return 495;
  permanent[0]=0xA7; permanent[39999]=0x5A;
  for(i=0;i<64;i++) private_live[i]=i+11;
  if(!I386BackingCheckSave(&check,&private_heap,control)) return 496;
  temporary=I386MemAlloc(control,160);
  if(!temporary || !I386MemFree(temporary) || !I386BackingCheckRestored(&check)) return 497;
  leak=I386HeapAlloc(&private_heap,64);
  if(!leak || I386BackingCheckRestored(&check) || !I386HeapFree(&private_heap,leak) ||
      !I386BackingCheckRestored(&check)) return 498;
  leak=I386HeapAlloc(heap,64);
  if(!leak || I386BackingCheckRestored(&check) || !I386HeapFree(heap,leak) ||
      !I386BackingCheckRestored(&check)) return 499;
  leak=I386MemAlloc(control,64);
  if(!leak || I386BackingCheckRestored(&check) || !I386MemFree(leak) ||
      !I386BackingCheckRestored(&check)) return 500;
  for(i=0;i<64;i++) if(private_live[i]!=(i+11)(U8)) return 501;
  if(permanent[0]!=0xA7 || permanent[39999]!=0x5A ||
      !I386MemFree(permanent) || !I386HeapFree(&private_heap,private_live) ||
      !I386MemHeapDestroy(control) || !I386MemBackingDestroy(pool) ||
      heap->used || heap->allocations || private_heap.used || private_heap.allocations ||
      !I386HeapValid(heap) || !I386HeapValid(&private_heap) || (GetRFlags^flags)&0x200) return 502;
  return 0;
}
