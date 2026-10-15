CTask *pu_child;I64 pu_value;Bool pu_release;
I64 PUSync(){CTask *t=NULL;I64 r=PopUp("6*7;",Fs,&t);return r==42&&!t&&!Fs->popup_task;}
I64 PUWide(){return PopUp("-7;",Fs)==-7&&PopUp("0x123456789ABCDEF0;",Fs)==0x123456789ABCDEF0;}
U8 *PUAsyncSource(){return MStrPrint("while(!*0x%X(Bool *))Yield;*0x%X(I64 *)=42;",&pu_release,&pu_value);}
I64 PUAsyncStart(){I64 r;U8 *s;pu_release=FALSE;pu_value=0;pu_child=NULL;s=PUAsyncSource;r=PopUp(s,NULL,&pu_child);Free(s);return !r&&TaskValidate(pu_child)&&!Fs->popup_task;}
I64 PUAsyncFinish(){pu_release=TRUE;while(TaskValidate(pu_child))Yield;return pu_value==42&&pu_child!=NULL;}
I64 PUHeap(){I64 b=Fs->data_heap->used_u8s,i;for(i=0;i<3;i++)if(!PUSync)return 0;for(i=0;i<32;i++)Yield;return Fs->data_heap->used_u8s==b;}
U0 Report(U8 *s){while(*s)OutU8(0xE9,*s++);}
I64 *v=CAlloc(40);
Report("POP sync\n");v[0]=PUSync;Report("POP wide\n");v[1]=PUWide;
Report("POP async start\n");v[2]=PUAsyncStart;Report("POP async finish\n");v[3]=PUAsyncFinish;
Report("POP heap\n");v[4]=PUHeap;
U8 *line=MStrPrint("EXPORT popup-execution.bin %X %X\n",v,40);Report(line);Free(line);
Report("DONE original popup execution\n");
