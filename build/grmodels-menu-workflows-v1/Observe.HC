#ifdef I386_PUBLIC_USER_INCLUDED
#include "/Adam/Gr/Gr.HH"
#endif

I64 model_pointer[2];

U0 ModelLog(U8 *text)
{
  while (*text) OutU8(0xE9,*text++);
}

U0 ModelPointerWatch()
{
  while (TRUE) {
    model_pointer[0]=ms.pos.x;
    model_pointer[1]=ms.pos.y;
    Sleep(1);
  }
}

U0 ModelCapture()
{
  CDoc *doc=DocPut;
  CDocBin *bin=doc->bin_head.last;
  U8 line[128];
  if (bin==&doc->bin_head || !bin->data || bin->size<10 ||
      *bin->data!=SPT_MESH) {
    ModelLog("FAIL Models did not place a mesh in the document\n");
    return;
  }
  StrPrint(line,"EXPORT MenuMesh.bin %X %X\n",bin->data,bin->size);
  ModelLog(line);
  Sleep(2000);
  ModelLog("MODELS document mesh ready\n");
}

U0 ModelObserve()
{
  U8 line[128];
  Spawn(&ModelPointerWatch,Fs,"Models pointer observer");
  StrPrint(line,"MODELS pointer %X\n",model_pointer);
  ModelLog(line);
}
