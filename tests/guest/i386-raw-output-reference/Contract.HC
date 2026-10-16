#define RO_BYTES 192048
U0 ROWarm()
{
 I64 col=text.raw_col,flags=text.raw_flags;Bool raw=Raw(TRUE);
 RawPutChar(32);Raw(raw);text.raw_col=col;text.raw_flags=flags;
 if(!text.raw_scrn_image)throw('RawCache',TRUE);
}
I64 ROCapture(I64 mode,U8 *output)
{
 I64 before=Fs->data_heap->used_u8s,col=text.raw_col,flags=text.raw_flags,m=0,i;
 I64 *meta=output;U8 *cache=text.raw_scrn_image,read_plane;
 CDoc *put=DocPut,*display=DocDisplay,*border=DocBorder;CDocEntry *last=put->head.last;
 Bool raw=Raw(TRUE),suspended=Suspend(sys_winmgr_task),active;
 MemSet(output,0,RO_BYTES);text.raw_scrn_image=output+48;
 text.raw_col=0;text.raw_flags=0;
 OutU8(0x3C4,2);OutU8(0x3C5,15);MemSet(text.vga_alias,0,38400);
 if(mode==0)RawPutChar('A');
 if(mode==1)Print("AB\tC");
 if(mode==2)Print("AB%cC",8);
 if(mode==3)Print("A\nB");
 if(mode==4)Print("%cFG,4%cA",36,36);
 if(mode==5)PutChars(0x2424);
 if(mode==6){text.raw_flags=RWF_SHOW_DOLLAR;Print("%cFG,4%c",36,36);}
 if(mode==7){text.raw_col=4799;Print("AB");}
 if(mode==8){text.raw_col=4799;text.raw_flags=RWF_SCROLL;Print("AB");}
 if(mode==9){text.raw_col=79;RawPutChar('\t');RawPutChar('B');}
 if(mode==10){RawPutChar(219);RawPutChar(179);}
 if(mode==11){RawPutChar(0);RawPutChar(1);RawPutChar(127);RawPutChar('Z');}
 if(mode==12){Raw(FALSE);RawPutChar('A');}
 meta[0]=text.raw_col;meta[1]=text.raw_flags;meta[2]=text.cols;meta[3]=text.rows;
 active=IsRaw;meta[4]=active;
 OutU8(0x3CE,4);read_plane=InU8(0x3CF);
 for(i=0;i<4;i++){OutU8(0x3CF,i);MemCpy(output+48+38400*(i+1),text.vga_alias,38400);}
 OutU8(0x3CF,read_plane);
 if(text.cols==80&&text.rows==60)m|=1;
 if(DocPut==put&&DocDisplay==display&&DocBorder==border&&put->head.last==last)m|=2;
 text.raw_scrn_image=cache;text.raw_col=col;text.raw_flags=flags;
 Raw(raw);Suspend(sys_winmgr_task,suspended);
 if(IsRaw==raw&&text.raw_scrn_image==cache&&text.raw_col==col&&text.raw_flags==flags)m|=4;
 if(Fs->data_heap->used_u8s==before)m|=8;
 if(active==(mode!=12))m|=16;
 meta[5]=m;return m;
}
I64 ROSave(I64 mode)
{
 I64 before=Fs->data_heap->used_u8s,m;U8 *output=CAlloc(RO_BYTES),*name;
 m=ROCapture(mode,output);name=MStrPrint("C:/RawOutput%d.BIN",mode);
 if(FileWrite(name,output,RO_BYTES)<=0)m=0;
 Free(name);Free(output);
 if(m!=31||Fs->data_heap->used_u8s!=before)throw('RawOut',TRUE);
 return m;
}
