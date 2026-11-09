I64 packet_rows[10240][5],packet_count;
U0 PacketLog(U8 *s){while(*s)OutU8(0xE9,*s++);}
U0 PacketContract()
{
  I64 axis,button,sign,value,*r;U8 h,a,b;U8 *line;
  packet_count=0;
  for(axis=0;axis<2;axis++)for(button=0;button<8;button++)
    for(sign=0;sign<2;sign++)for(value=0;value<256;value++) {
      h=8|button;a=b=0;
      if(axis){h|=sign<<5;b=value;}else{h|=sign<<4;a=value;}
      r=packet_rows[packet_count++];PacketDecode(h,a,b,0,3,r);
    }
  for(button=0;button<8;button++)for(value=0;value<256;value++) {
    r=packet_rows[packet_count++];PacketDecode(8|button,0,0,value,4,r);
  }
  line=MStrPrint("EXPORT packet-rows.bin %X %X\n",packet_rows,packet_count*40);PacketLog(line);Free(line);
  PacketLog("PACKET DONE\n");
}
