U0 LGOut(U8 *s) {while(*s)OutU8(0xE9,*s++);}

U0 LGWatch(CTask *owner)
{
  while(num_sel_gates<1)Sleep(1);
  LGOut("LOGIC gate submitted\n");
  while(!gate_type_table)Sleep(1);
  LGOut("LOGIC table ready\n");
  while(num_inputs_entered<2)Sleep(1);
  LGOut("LOGIC inputs submitted\n");
  while(num_outputs_entered<1)Sleep(1);
  LGOut("LOGIC output submitted\n");
  while(!owner->draw_it)Sleep(1);
  if(output_found!=0xC0 || gate_type_table[0xC0]!=GT_AND ||
      (input1_table[0xC0]|input2_table[0xC0])!=0xFC)
    LGOut("FAIL Logic synthesis of typed AND\n");
  else
    LGOut("LOGIC AND ready\n");
}

U0 LGProbe()
{
  CTask *watch=Spawn(&LGWatch,Fs,"Logic test observer");
  U8 *old_draw=Fs->draw_it;
  LGOut("LOGIC start\n");
  DigitalLogic;
  Kill(watch);
  if(Fs->draw_it!=old_draw)LGOut("FAIL Logic caller state\n");
  LGOut("LOGIC returned\n");
}
