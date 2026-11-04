I64 InputTimeReferenceContract()
{
  I64 flags=GetRFlags,key=kbd.timestamp,new_key=kbd.new_key_timestamp;
  I64 mouse=ms_hard.timestamp,mask=0;
  SetRFlags(flags&~512);
  kbd.timestamp=0;kbd.new_key_timestamp=0;ms_hard.timestamp=0;
  if(KbdMsEvtTime==0)mask|=1;
  kbd.timestamp=2;kbd.new_key_timestamp=1;ms_hard.timestamp=3;
  if(KbdMsEvtTime==3)mask|=2;
  kbd.timestamp=2;kbd.new_key_timestamp=1;ms_hard.timestamp=2;
  if(KbdMsEvtTime==1)mask|=4;
  kbd.timestamp=3;kbd.new_key_timestamp=2;ms_hard.timestamp=1;
  if(KbdMsEvtTime==2)mask|=8;
  kbd.timestamp=3;kbd.new_key_timestamp=1;ms_hard.timestamp=2;
  if(KbdMsEvtTime==1)mask|=16;
  kbd.timestamp=key;kbd.new_key_timestamp=new_key;ms_hard.timestamp=mouse;
  SetRFlags(flags);
  return mask;
}
