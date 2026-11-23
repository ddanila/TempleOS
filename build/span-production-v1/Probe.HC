I64 span_pointer[2];
U0 SPLog(U8 *s)
{
  while(*s) OutU8(0xE9,*s++);
}

I64 SPMassCount()
{
  I64 count=0;
  MyMass *mass=ode->next_mass;
  while(mass!=&ode->next_mass) {
    count++;
    mass=mass->next;
  }
  return count;
}

U0 SPWatch(CTask *owner)
{
  I64 initial_count;
  F64 paused_t;
  U8 line[120];
  while(!owner->popup_task) Sleep(1);
  StrPrint(line,"SPAN instructions %X\n",span_pointer);
  SPLog(line);
  while(owner->popup_task) {
    span_pointer[0]=ms.pos.x;
    span_pointer[1]=ms.pos.y;
    Sleep(1);
  }
  if(!ode || !owner->draw_it) return;
  initial_count=SPMassCount;
  StrPrint(line,"SPAN editor %X initial masses %d\n",span_pointer,initial_count);
  SPLog(line);
  while(SPMassCount==initial_count) {
    span_pointer[0]=ms.pos.x;
    span_pointer[1]=ms.pos.y;
    Sleep(1);
  }
  if(SPMassCount!=initial_count+1) SPLog("FAIL Span added mass count\n");
  SPLog("SPAN placed mass\n");
  while(!run_bttn.state || ode->t<0.05) Sleep(1);
  SPLog("SPAN simulation advanced\n");
  while(run_bttn.state || !(ode->flags&ODEF_PAUSED)) Sleep(1);
  paused_t=ode->t;
  Sleep(250);
  if(ode->t!=paused_t) SPLog("FAIL Span clock advanced while paused\n");
  SPLog("SPAN stopped\n");
}

U0 SPCheckSong()
{
  CSndData *note=scrncast.snd_head.next;
  I64 expected[6],count=0;
  U8 line[160];
  expected[0]=Note2Ona(7,5);
  expected[1]=Note2Ona(5,5);
  expected[2]=Note2Ona(7,5);
  expected[3]=Note2Ona(5,5);
  expected[4]=Note2Ona(10,4);
  expected[5]=Note2Ona(5,5);
  while(note!=&scrncast.snd_head && count<6) {
    if(note->ona>0) {
      StrPrint(line,"SPAN note %d = %d\n",count,note->ona);
      SPLog(line);
      if(note->ona!=expected[count])
        SPLog("FAIL Span soundtrack note\n");
      count++;
    }
    note=note->next;
  }
  if(count!=6 || InU8(0x61)&3)
    SPLog("FAIL Span soundtrack length or cleanup\n");
  else
    SPLog("SPAN speaker off\n");
}

U0 SPProbe()
{
  CTask *watch=Spawn(&SPWatch,Fs,"Span test observer");
  U8 *draw=Fs->draw_it;
  ScrnCast(TRUE,TRUE);
  Span;
  ScrnCast(FALSE,TRUE);
  SPCheckSong;
  Kill(watch);
  if(Fs->draw_it!=draw || Fs->next_ode!=&Fs->next_ode)
    SPLog("FAIL Span task cleanup\n");
  SPLog("SPAN returned\n");
}
