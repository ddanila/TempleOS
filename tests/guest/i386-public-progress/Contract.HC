I64 PublicProgressContract()
{
  CProgress saved[4];I64 mask=0;
  MemCpy(saved,sys_progresses,sizeof(saved));
  if(&progress1==&sys_progresses[0].val && &progress2==&sys_progresses[1].val &&
     &progress3==&sys_progresses[2].val && &progress4==&sys_progresses[3].val)mask|=1;
  if(&progress1_max==&sys_progresses[0].max && &progress2_max==&sys_progresses[1].max &&
     &progress3_max==&sys_progresses[2].max && &progress4_max==&sys_progresses[3].max)mask|=2;
  if(progress1_desc==sys_progresses[0].desc && progress2_desc==sys_progresses[1].desc &&
     progress3_desc==sys_progresses[2].desc && progress4_desc==sys_progresses[3].desc)mask|=4;
  if(&progress1_t0==&sys_progresses[0].t0 && &progress2_t0==&sys_progresses[1].t0 &&
     &progress3_t0==&sys_progresses[2].t0 && &progress4_t0==&sys_progresses[3].t0 &&
     &progress1_tf==&sys_progresses[0].tf && &progress2_tf==&sys_progresses[1].tf &&
     &progress3_tf==&sys_progresses[2].tf && &progress4_tf==&sys_progresses[3].tf)mask|=8;
  progress1=11;progress2_max=22;progress3_desc[0]='X';progress3_desc[1]=0;progress4_t0=1.5;progress4_tf=2.5;
  if(sys_progresses[0].val==11 && sys_progresses[1].max==22 &&
     sys_progresses[2].desc[0]=='X' && sys_progresses[3].t0==1.5 && sys_progresses[3].tf==2.5)mask|=16;
  sys_progresses[0].max=33;sys_progresses[1].val=44;sys_progresses[2].desc[0]='Y';
  if(progress1_max==33 && progress2==44 && progress3_desc[0]=='Y')mask|=32;
  MemCpy(sys_progresses,saved,sizeof(saved));return mask;
}
