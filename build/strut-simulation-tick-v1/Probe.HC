I64 strut_pointer[7];
U0 STLog(U8 *s) {while(*s)OutU8(0xE9,*s++);}

U0 STWatch(CTask *owner)
{
  MyMass *mass;
  I64 n,stage=0,last_mode=-1,last_button=-1;
  F64 sx,sy,last_tick=0;
  U8 line[100];
  while(!ode || !owner->draw_it)Sleep(1);
  StrPrint(line,"STRUT editor %X\n",strut_pointer);
  STLog(line);
  while(TRUE) {
    strut_pointer[0]=ms.pos.x;
    strut_pointer[1]=ms.pos.y;
    strut_pointer[2]=ms.lb;
    if(stage>=2 && (last_mode!=edit_mode_bttn.state || last_button!=ms.lb)) {
      last_mode=edit_mode_bttn.state;
      last_button=ms.lb;
      StrPrint(line,"STRUT input mode=%d button=%d at %d,%d\n",
          last_mode,last_button,ms.pos.x,ms.pos.y);
      STLog(line);
    }
    if(ode) {
      //Diagnostic only. The native window worker has no ODE update phase.
      if(main_mode_bttn.state==MMD_PLAY && tS-last_tick>=0.033) {
        last_tick=tS;
        ODEsUpdate(owner);
      }
      n=0;
      for(mass=ode->next_mass;mass!=&ode->next_mass;mass=mass->next) {
        if(n<2) {
          W2S(mass->x,mass->y,&sx,&sy);
          strut_pointer[3+2*n]=sx+task->pix_left+task->scroll_x;
          strut_pointer[4+2*n]=sy+task->pix_top+task->scroll_y;
        }
        n++;
      }
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
