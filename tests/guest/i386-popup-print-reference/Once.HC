I64 PPValue(){return PopUpPrint("%d+%d;",19,23)==42;}
I64 PPWide(){return PopUpPrint("-0x%X;",7)==-7&&PopUpPrint("0x%X;",0x123456789ABCDEF0)==0x123456789ABCDEF0;}
I64 PPString(){return PopUpPrint("%s%d%c","6*",7,59)==42;}
I64 PPQuote(){return PopUpPrint("StrLen(\"%Q\");","a\"b")==3;}
I64 PPFloat(){return PopUpPrint("ToI64(2*(%.4f));",1.5)==3;}
I64 PPHeap(){I64 b=Fs->data_heap->used_u8s,i;for(i=0;i<3;i++)if(!PPValue)return 0;return Fs->data_heap->used_u8s==b;}
U0 Report(U8 *s){while(*s)OutU8(0xE9,*s++);}
I64 *v=CAlloc(48);v[0]=PPValue;v[1]=PPWide;v[2]=PPString;v[3]=PPQuote;v[4]=PPFloat;v[5]=PPHeap;
U8 *line=MStrPrint("EXPORT popup-print.bin %X %X\n",v,48);Report(line);Free(line);
Report("DONE original popup print\n");
