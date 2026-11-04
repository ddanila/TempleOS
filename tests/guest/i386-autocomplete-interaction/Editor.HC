//Run through the ordinary editor; ACUIWatch observes its real focused document.
public U0 ACUIEdit()
{
  CDoc *doc=DocNew("C:/ACUIEdited.HC",Fs);
  U8 *body;
  I64 size;
  if(!doc)throw('UIEdit',TRUE);
  ACUIArm(Fs);
  ACUILog("ACUI editor opening\n");
  DocEd(doc);
  body=DocSave(doc,&size);
  U8 *line;
  if(acui_native && !FileWrite("C:/ACUIEdited.DATA",body,size))throw('UIWrite',TRUE);
  line=MStrPrint("EXPORT ACUIEdited.DATA %X %X\n",body,size);
  ACUILog(line);Free(line);
  //Keep the exported body alive until the host has copied it.
  Sleep(1000);Free(body);
  DocDel(doc);
  ACUILog("ACUI editor closed\n");
}
