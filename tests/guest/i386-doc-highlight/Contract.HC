Bool HL(CDocEntry *entry,U8 *source,U64 colors,I64 state,I64 comments)
{
  U8 *text=StrNew(source);
  I64 base=Fs->data_heap->used_u8s,len=StrLen(text),i;
  U32 *out=DocHighlight(entry,text,len,0x1234FF00);
  Bool ok=out && !out[len] && !StrCmp(text,source);
  if(out)for(i=0;i<len;i++)
    if(out[i]!=(0x1234F000|((colors>>(4*i))&15)<<8|source[i]))ok=FALSE;
  if(entry->settings.state!=state || entry->settings.comment_depth!=comments ||
     entry->settings.paren_depth || entry->settings.brace_depth)ok=FALSE;
  if(!ok && out) {
    U8 *line=MStrPrint("OBS highlight %s first %X state %d comment %d\n",source,out[0],entry->settings.state,entry->settings.comment_depth),*scan=line;
    while(*scan)OutU8(0xE9,*scan++);Free(line);
  }
  Free(out);
  if(Fs->data_heap->used_u8s!=base)ok=FALSE;
  Free(text);
  return ok;
}
I64 JRContract(I64 unused)
{
  CDocEntry entry;
  I64 mask=0;
  MemSet(&entry,0,sizeof(entry));
  if(HL(&entry,"(()){{}}",0xF77FF77F,DOCSS_NORMAL,0))mask|=1;
  MemSet(&entry,0,sizeof(entry));
  if(HL(&entry,"'a'",0x666,DOCSS_NORMAL,0))mask|=2;
  MemSet(&entry,0,sizeof(entry));
  if(HL(&entry,"\"hi",0x666,DOCSS_DBL_QUOTE,0) &&
     HL(&entry,"!\"",0x66,DOCSS_NORMAL,0))mask|=4;
  MemSet(&entry,0,sizeof(entry));
  if(HL(&entry,"/*x/*y*/",0x22222222,DOCSS_COMMENT,1) &&
     HL(&entry,"z*/",0x222,DOCSS_NORMAL,0))mask|=8;
  MemSet(&entry,0,sizeof(entry));
  if(HL(&entry,"//x",0x222,DOCSS_CPP_Z_COMMENT,0) &&
     HL(&entry,"tail",0x2222,DOCSS_CPP_Z_COMMENT,0))mask|=16;
  MemSet(&entry,0,sizeof(entry));
  if(HL(&entry,"I64",0x999,DOCSS_NORMAL,0))mask|=32;
  return mask;
}
