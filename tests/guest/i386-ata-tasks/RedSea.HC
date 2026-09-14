#include "/Kernel/I386/RedSeaTask.HH"
#include "/Kernel/I386/FileRead.HH"
CI386RedSea volumes[2];
CI386RedSeaIo volume_io;
U32 fs_stage,fs_queued,fs_done;
extern U0 FileWriter(I64 unused);
extern U0 FileReader(I64 unused);
I64 FileSessionTest()
{
  CI386RedSeaEntry entry;
  U8 buffer[512],*bytes;
  I64 i,round,size=-1;
  if(!I386RedSeaMount(&volumes[0],&disks[0],2048) ||
      !I386RedSeaMount(&volumes[1],&disks[1],2048) ||
      I386RedSeaFind(&volumes[0],volumes[0].root,"Data.BIN",&entry)!=1) return 20;
  if(!I386RedSeaTaskIoInit(&volume_io,&channel) || I386RedSeaTaskIoInit(&volume_io,&channel) ||
      !I386RedSeaTaskBind(&volumes[0],&volume_io) || !I386RedSeaTaskBind(&volumes[1],&volume_io) ||
      I386RedSeaTaskBind(&volumes[0],&volume_io)) return 21;
  //Every bound sector operation requires the complete-operation lease.
  if(I386RedSeaFind(&volumes[0],volumes[0].root,"Data.BIN",&entry)!=-1 ||
      I386RedSeaWrite(&volumes[0],&entry,0,buffer,512)!=-1 ||
      I386RedSeaFlush(&volumes[0]) || channel.poisoned ||
      !I386RedSeaBegin(&volumes[0]) || I386RedSeaBegin(&volumes[1]) ||
      !I386RedSeaEnd(&volumes[0]) || root.io_locks) return 22;
  workers[0]=I386TaskSpawn(&scheduler,&heap,8192,&FileWriter,0);
  workers[1]=I386TaskSpawn(&scheduler,&heap,8192,&FileReader,0);
  if(!workers[0] || !workers[1]) return 23;
  I386PicMask(0xFFFC);
  for(round=0;round<1000;round++) {
    I386SchedYield(&scheduler);
    if(channel.head) fs_queued++;
    if(channel.owner && I386RedSeaFileRead(&volumes[0],&heap,volumes[0].root,"Data.BIN")) return 24;
    if(workers[0]->task.finished && workers[1]->task.finished) break;
  }
  I386PicMask(0xFFFF);
  if(errors || fs_done!=2 || fs_stage!=2 || !fs_queued || channel.owner || channel.head ||
      channel.poisoned || root.io_locks || (GetRFlags&0x200)) return 25;
  for(i=0;i<2;i++) if(!I386TaskDestroy(workers[i])) return 26;
  bytes=I386RedSeaFileRead(&volumes[1],&heap,volumes[1].root,"/Data.BIN",&size);
  if(!bytes || size!=1024 || bytes[size] || root.io_locks) return 27;
  for(i=0;i<size;i++) if(bytes[i]!=0x42) return 28;
  if(!I386HeapFree(&heap,bytes) || heap.used || heap.allocations || !I386HeapValid(&heap)) return 29;
  return 0;
}
U0 FileWriter(I64 unused)
{
  CI386RedSeaEntry entry;
  U8 buffer[1024];
  I64 i;
  for(i=0;i<1024;i++) buffer[i]=0x6C;
  if(!I386RedSeaBegin(&volumes[0])) { errors++; return; }
  fs_stage=1;
  if(I386RedSeaFind(&volumes[0],volumes[0].root,"Data.BIN",&entry)!=1 ||
      I386RedSeaWrite(&volumes[0],&entry,0,buffer,1024)!=1024 ||
      !I386RedSeaFlush(&volumes[0]) || I386TaskSelf->io_locks!=1 || (GetRFlags&0x200)) errors++;
  fs_stage=2;
  if(!I386RedSeaEnd(&volumes[0]) || I386TaskSelf->io_locks) errors++;
  fs_done++;
}
U0 FileReader(I64 unused)
{
  U8 *bytes;
  I64 i,size=-1;
  if(fs_stage!=1) errors++;
  bytes=I386RedSeaFileRead(&volumes[0],&heap,volumes[0].root,"/Data.BIN",&size);
  if(!bytes || fs_stage!=2 || size!=1024 || bytes[size] || I386TaskSelf->io_locks ||
      (GetRFlags&0x200)) { errors++; return; }
  for(i=0;i<size;i++) if(bytes[i]!=0x6C) errors++;
  if(!I386HeapFree(&heap,bytes)) errors++;
  fs_done++;
}
Bool FileSessionReadFailure()
{
  CI386RedSeaEntry entry;
  I64 used=heap.used,allocations=heap.allocations,size=0x12345678;
  U8 *bytes;
  volumes[0].sectors=32769-volumes[0].start;
  entry.attr=0x800; entry.block=32767; entry.size=1024;
  if(!I386RedSeaBegin(&volumes[0])) { errors++; return TRUE; }
  bytes=I386RedSeaReadAll(&volumes[0],&heap,&entry,&size);
  if(bytes || size!=0x12345678 || heap.used!=used || heap.allocations!=allocations ||
      !I386HeapValid(&heap) || !channel.poisoned) errors++;
  if(bytes) I386HeapFree(&heap,bytes);
  if(!I386RedSeaEnd(&volumes[0]) || I386TaskSelf->io_locks) errors++;
  return bytes!=0;
}
#include "/Kernel/I386/RedSea.HC"
#include "/Kernel/I386/RedSeaWrite.HC"
#include "/Kernel/I386/RedSeaTask.HC"
#include "/Kernel/I386/FileRead.HC"
