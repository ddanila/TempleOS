U0 InputTimeLog(U8 *s){while(*s)OutU8(0xE9,*s++);}
Bool InputKeyContract()
{
  I64 ch,scan,base=KbdMsEvtTime,count;
  Bool result;
  FlushMsgs;count=kbd.cnt;
  InputTimeLog("INPUT TIME key ready\n");
  if(GetMsg(&ch,&scan,1<<MSG_KEY_DOWN)!=MSG_KEY_DOWN || ch!='a' || (scan&255)!=30)return FALSE;
  if(GetMsg(&ch,&scan,1<<MSG_KEY_UP)!=MSG_KEY_UP || ch!='a' || (scan&255)!=30)return FALSE;
  result=kbd.cnt>=count+2 && (kbd.last_down_scan_code&255)==30 &&
    !(kbd.last_down_scan_code&SCF_KEY_UP) && (kbd.scan_code&SCF_KEY_UP) &&
    !Bt(kbd.down_bitmap,30) && !Bt(kbd.down_bitmap2,30) &&
    kbd.timestamp>=kbd.new_key_timestamp && kbd.new_key_timestamp>base &&
    KbdMsEvtTime==kbd.new_key_timestamp && kbd.irqs_working;
  InputTimeLog("INPUT TIME key done\n");return result;
}
Bool InputMouseContract()
{
  I64 x,y,buttons,packets,old_packets,base,key_raw,key_new,end,ch,scan;
  Bool result;
  //Drain the submitted command's key release before measuring mouse-only activity.
  FlushMsgs;Sleep(20);
  base=KbdMsEvtTime;key_raw=kbd.timestamp;key_new=kbd.new_key_timestamp;
  end=cnts.jiffies+5000;MouseGet(&x,&y,&buttons,&old_packets);
  InputTimeLog("INPUT TIME mouse ready\n");
  do {
    Yield;MouseGet(&x,&y,&buttons,&packets);
  } while(packets==old_packets && cnts.jiffies<end);
  result=packets>old_packets && kbd.timestamp==key_raw &&
    kbd.new_key_timestamp==key_new && KbdMsEvtTime>base && KbdMsEvtTime<=GetTSC;
  InputTimeLog("INPUT TIME mouse checked\n");
  if(GetMsg(&ch,&scan,1<<MSG_KEY_DOWN)!=MSG_KEY_DOWN || ch!='b')result=FALSE;
  InputTimeLog("INPUT TIME mouse done\n");return result;
}
