U0 AELog(U8 *s){while(*s)OutU8(0xE9,*s++);}
U0 AEExport(U8 *name,CDoc *doc){I64 n;U8 *b=DocSave(doc,&n),*s=MStrPrint("EXPORT %s %X %X\n",name,b,n);AELog(s);Free(s);Sleep(1000);Free(b);}
U0 AECheck(){CDoc *ap=adam_task->put_doc,*cp=Fs->put_doc,*dst=DocNew,*local=DocNew;
U8 *before=NULL,*after=NULL,*local_before=NULL,*s;I64 n1,n2,local_n,mask=0;Bool single=Bt(&sys_semas[SEMA_SINGLE_USER],0),raw=Raw(OFF);
try {Adam("0;");if(Fs!=adam_task)mask|=1;Fs->put_doc=local;adam_task->put_doc=dst;local_before=DocSave(local,&local_n);
before=DocSave(dst,&n1);Bts(&sys_semas[SEMA_SINGLE_USER],0);AdamErr("suppressed:%d\n",1);
after=DocSave(dst,&n2);if(n1==n2 && !MemCmp(before,after,n1))mask|=2;Free(after);after=NULL;
Btr(&sys_semas[SEMA_SINGLE_USER],0);AdamErr("route:%d/%s\n",7,"ok");
after=DocSave(dst,&n2);if(n2>n1)mask|=4;Free(before);before=NULL;Free(after);after=NULL;AEExport("adam-err-route.DD",dst);
before=DocSave(local,&n1);if(n1==local_n && !MemCmp(before,local_before,n1))mask|=8;Free(before);before=NULL;
Adam("AdamErr(\"direct:%%d\\n\",9);");AEExport("adam-err-direct.DD",dst);
if(Fs->put_doc==local && adam_task->put_doc==dst)mask|=16;
}catch{}
BEqu(&sys_semas[SEMA_SINGLE_USER],0,single);adam_task->put_doc=ap;Fs->put_doc=cp;Raw(raw);Free(before);Free(after);Free(local_before);DocDel(dst);DocDel(local);
s=MStrPrint("EXPORT adam-err-mask.bin %X 8\n",&mask);AELog(s);Free(s);AELog("ADAM ERR DONE\n");Sleep(1000);}
