I64 strut_pointer[3];
U0 STLog(U8 *s) {while(*s)OutU8(0xE9,*s++);}

U0 STWatch(CTask *owner)
{
  MyMass *mass;
  I64 n,stage=0;
  U8 line[100];
  while(!ode || !owner->draw_it)Sleep(1);
  StrPrint(line,"STRUT editor %X\n",strut_pointer);
  STLog(line);
  while(TRUE) {
    strut_pointer[0]=ms.pos.x;
    strut_pointer[1]=ms.pos.y;
    strut_pointer[2]=ms.lb;
    if(ode) {
      n=0;
      for(mass=ode->next_mass;mass!=&ode->next_mass;mass=mass->next)n++;
      if(stage==0 && n==1) {STLog("STRUT first mass\n");stage++;}
      if(stage==1 && n==2) {STLog("STRUT second mass\n");stage++;}
      if(stage==2 && ode->next_spring!=&ode->next_spring) {
        STLog("STRUT spring\n");stage++;
      }
      if(stage==3 && main_mode_bttn.state==MMD_PLAY) {
        STLog("STRUT play\n");stage++;
      }
      if(stage==4 && ode->t>0.01) {STLog("STRUT simulation advanced\n");stage++;}
    }
    Sleep(1);
  }
}

U0 STProbe()
{
  CTask *watch=Spawn(&STWatch,Fs,"Strut test observer");
  U8 *draw=Fs->draw_it;
  STLog("STRUT instructions\n");
  Strut;
  Kill(watch);
  if(ode || Fs->draw_it!=draw)STLog("FAIL Strut caller state\n");
  STLog("STRUT returned\n");
}
