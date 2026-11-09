U0 ULLog(U8*s){while(*s)OutU8(0xE9,*s++);}
U0 ULChild()
{
  CTask *old_focus=ul_return_focus;
  CDoc *old_put=DocPut,*old_display=DocDisplay,*doc=DocNew("C:/UserLegacy.DD");
  U8 *welcome,*saved,*s;
  I64 mask=0,size,stored_size;
  WinFocus(Fs);DocEd(doc);
  if(DocPut==old_put && DocDisplay==old_display)mask|=1;
  welcome=FileRead("::/Doc/Start.DD",&size);saved=DocSave(old_put,&stored_size);
  if(welcome && saved && stored_size>=size && !MemCmp(welcome,saved,size))mask|=2;
  Free(welcome);Free(saved);DocDel(doc);
  if(TaskValidate(old_focus))WinFocus(old_focus);
  s=MStrPrint("USER LEGACY MASK %d\n",mask);ULLog(s);Free(s);ULLog("USER LEGACY DONE\n");
}
ULChild;
