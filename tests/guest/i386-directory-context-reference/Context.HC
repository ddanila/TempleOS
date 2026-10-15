U8 dc_base[STR_LEN];
Bool DCSetup(U8 drive)
{
 U8*root=MStrPrint("%c:/",drive),*base=MStrPrint("%c:/Probe/DirContext",drive);
 Bool ok=Cd(root);DirMk("Probe");Cd("Probe");DirMk("DirContext");ok=ok&&Cd(base);
 DirMk("A");DirMk("A/Nested");DirMk("B");StrCpy(dc_base,Fs->cur_dir);
 Free(root);Free(base);return ok;
}
I64 DCContract(I64 mode)
{
 I64 before=Fs->data_heap->used_u8s,m=0;CDirContext*context=NULL,*inner=NULL;
 CDrv*drive=Fs->cur_dv;CDoc*put=DocPut,*display=DocDisplay,*border=DocBorder;
 U8*want=dc_base,*mask="note.HC",*active=MStrPrint("%s/A",dc_base),*nested=MStrPrint("%s/A/Nested",dc_base);
 Bool old_silent=Silent(TRUE),made=FALSE,fields=FALSE,active_ok=FALSE,restored=FALSE;
 if(mode==0)context=DirContextNew("note.HC");
 else if(mode==1||mode==8){context=DirContextNew("A/*.HC");want=active;mask="*.HC";}
 else if(mode==2){context=DirContextNew("  A/note.HC  ");want=active;}
 else if(mode==3){context=DirContextNew("A/*.HC;*.HH");want=active;mask="*.HC;*.HH";}
 else if(mode==4){context=DirContextNew("A",TRUE);want=active;mask="*";}
 else if(mode==5){context=DirContextNew("",TRUE);mask="*";}
 else if(mode==6){context=DirContextNew("A",FALSE,FALSE,TRUE);want=active;mask="";}
 else if(mode==7){context=DirContextNew("Made/Deep/*.HC",FALSE,TRUE);want=MStrPrint("%s/Made/Deep",dc_base);mask="*.HC";made=TRUE;}
 else if(mode==9){context=DirContextNew("A/*.HC");want=active;mask="*.HC";}
 else if(mode==10)context=DirContextNew("A/Missing/Deep/*.HC");
 else if(mode==11)DirContextDel(NULL);
 if(mode<10){
  if(context)m|=1;
  if(context){
   fields=!StrCmp(context->old_dir,dc_base)&&context->old_dv==drive&&context->dv==drive;
   active_ok=!StrCmp(context->mask,mask)&&!StrCmp(Fs->cur_dir,want)&&Fs->cur_dv==drive;
   if(mode==9){
    inner=DirContextNew("Nested/*.HH");
    fields=fields&&inner&&inner->old_dv==drive&&inner->dv==drive&&!StrCmp(inner->old_dir,active);
    active_ok=active_ok&&inner&&!StrCmp(inner->mask,"*.HH")&&!StrCmp(Fs->cur_dir,nested);
    DirContextDel(inner);active_ok=active_ok&&!StrCmp(Fs->cur_dir,active);
   }
   DirContextDel(context,mode!=8);context=NULL;
   restored=!StrCmp(Fs->cur_dir,dc_base);
   if(mode==8)restored=!StrCmp(Fs->cur_dir,active);
  }
 }else{
  if(!context)m|=1;fields=TRUE; //No returned context fields exist for failure/null deletion.
  active_ok=!StrCmp(Fs->cur_dir,dc_base);restored=active_ok;
 }
 if(fields)m|=2;if(active_ok)m|=4;if(restored)m|=8;
 if(DocPut==put&&DocDisplay==display&&DocBorder==border&&Fs->cur_dv==drive)m|=16;
 if(context)DirContextDel(context);Cd(dc_base);Silent(old_silent);
 if(made)Free(want);Free(active);Free(nested);
 if(Fs->data_heap->used_u8s==before)m|=32;return m;
}
I64 DCCheck(I64 mode){I64 m=DCContract(mode);if(m!=63)throw('DirCtxt',TRUE);return m;}
