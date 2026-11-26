#ifdef I386_PUBLIC_USER_INCLUDED
#include "/Adam/Gr/Gr.HH"
#endif

I64 textdemo_pointer[2];

U0 TDMouseLog(U8 *s)
{while(*s)OutU8(0xE9,*s++);}

U0 TDMouseWatch()
{
  while(TRUE) {
    textdemo_pointer[0]=ms.pos.x;
    textdemo_pointer[1]=ms.pos.y;
    Sleep(1);
  }
}

U0 TextDemoMouse()
{
  CDoc *doc=DocNew,*put=DocPut,*display=DocDisplay,*border=DocBorder;
  CTask *observer;
  U8 line[96];
  I64 result;
  Fs->put_doc=doc;
  ExeFile("::/Demo/DolDoc/TextDemo.HC");
  Fs->put_doc=put;
  observer=Spawn(&TDMouseWatch,0,"TextDemo pointer",,Fs);
  StrPrint(line,"TEXTDEMO POINTER %X\n",textdemo_pointer);
  TDMouseLog(line);
  DocTop(doc);
  result=DocMenu(doc,DOF_DONT_HOME);
  if(result==DOCM_CANCEL && DocPut==put && DocDisplay==display && DocBorder==border)
    TDMouseLog("TEXTDEMO MOUSE LINK RESTORED\n");
  else
    TDMouseLog("TEXTDEMO MOUSE LINK FAILED\n");
  Kill(observer);
  DocDel(doc);
}
TextDemoMouse;
