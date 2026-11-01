U8 TILExpected[40]={
  1,19,2,58,21,39,2,58,41,59,2,58,61,78,2,58,1,78,2,58,
  1,78,2,14,1,78,16,28,1,78,30,42,1,78,44,58,1,78,2,58};
U0 TILHold(U8 *data){while(TRUE)Yield;}
I64 TILCase(I64 mode)
{
  CTask *t,*saved[24],*created[5],*ordered[5],*anchor=sys_winmgr_task;
  I64 old_inhibit[24],flags=GetRFlags,after,i,j,n,cnt=0,found=0,mask=0;
  U8 *expected=TILExpected+mode*20;Bool good=TRUE,restore=TRUE;
  n=5;
  for(i=0;i<n;i++)created[i]=Spawn(&TILHold,NULL,"Tile test",-1,Fs,8192);
  SetRFlags(flags&~512);
  t=anchor;
  do {
    if(cnt>=24)throw('TileCnt',TRUE);
    saved[cnt]=t;old_inhibit[cnt]=t->win_inhibit;cnt++;
    Bts(&t->win_inhibit,WIf_SELF_FOCUS);
    t=t->last_task;
  } while(t!=anchor);
  for(i=0;i<n;i++)Btr(&created[i]->win_inhibit,WIf_SELF_FOCUS);
  t=anchor;
  do {
    for(j=0;j<n;j++)if(t==created[j])ordered[found++]=t;
    t=t->last_task;
  } while(t!=anchor);
  for(i=0;i<n;i++) {
    if(FALSE)Bts(&ordered[i]->display_flags,DISPLAYf_NO_BORDER);
    else Btr(&ordered[i]->display_flags,DISPLAYf_NO_BORDER);
  }
  SetRFlags(flags);
  if(mode==1)WinTileHorz;else WinTileVert;
  after=GetRFlags;SetRFlags(flags);
  if(found==n)mask|=1;
  for(i=0;i<n;i++) {
    U8 *e=expected+i*4;
    if(ordered[i]->win_left!=e[0]||ordered[i]->win_right!=e[1]||
       ordered[i]->win_top!=e[2]||ordered[i]->win_bottom!=e[3]||
       ordered[i]->win_width!=e[1]-e[0]+1||ordered[i]->win_height!=e[3]-e[2]+1)good=FALSE;
  }
  if(good)mask|=2;
  if(!((flags^after)&512))mask|=4;
  SetRFlags(flags&~512);
  for(i=0;i<cnt;i++) {
    for(j=0;j<n;j++)if(saved[i]==created[j])break;
    if(j==n&&!Bt(&saved[i]->win_inhibit,WIf_SELF_FOCUS))restore=FALSE;
    saved[i]->win_inhibit=old_inhibit[i];
  }
  SetRFlags(flags);
  if(restore)mask|=8;
  for(i=0;i<n;i++)Kill(created[i]);
  if(sys_winmgr_task==anchor)mask|=16;
  return mask;
}
I64 TILCheck(I64 mode){I64 v=TILCase(mode);if(v!=31)throw('TileFail',TRUE);return v;}
