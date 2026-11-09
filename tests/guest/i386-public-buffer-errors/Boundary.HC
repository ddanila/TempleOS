#include "/Kernel/I386/PublicAssembly.HH"
#include "/Kernel/I386/PublicDebug.HH"
#include "/Compiler/PrsCompileFlags.HH"
U0 JBLog(U8 *s){while(*s)OutU8(0xE9,*s++);}
U0 JBCheck()
{
  I64 *rows=CAlloc(45*8),*r,i,used,code,caught,flags,mask;
  CCmpCtrl *cc;CLexHashTableContext context;
  CCodeCtrl active,saved,*boundary;
  CIntermediateCode *first,*second;CCodeMisc *first_misc,*second_misc;
  CAOT parent,parent_before;CAOTCtrl ctrl,ctrl_before;
  CDoc *doc,*old_doc;U8 *source,*old_fix,*line;
  mask=CCF_AOT_COMPILE|CCF_TARGET_I386|CCF_DONT_FREE_BUF;
  for(i=0;i<3;i++) {
    if(!i)source="asm {MOV EAX,}";
    else if(i==1)source="asm {JMP I8 @@far DU8 256 DUP(0x90);@@far:RET}";
    else source="asm {IMPORT BOUND_MISSING; CALL I32 BOUND_MISSING MOV EAX,}";
    r=rows+i*15;used=Fs->data_heap->used_u8s;code=Fs->code_heap->used_u8s;
    old_fix=dbg.fix_file_line;dbg.fix_file_line=NULL;
    old_doc=Fs->put_doc;doc=DocNew;Fs->put_doc=doc;
    cc=CmpCtrlNew(StrNew(source),CCF_TARGET_I386|CCF_AOT_COMPILE,"C:/Probe/JoinBoundary.HC");
    QueIns(cc,Fs->last_cc);COCInit(cc);
    first=ICAdd(cc,IC_IMM_I64,111,cmp.internal_types[RT_I64]);
    first_misc=COCMiscNew(cc,CMT_LABEL);first_misc->use_cnt=7;
    COCPush(cc);COCInit(cc);
    second=ICAdd(cc,IC_IMM_I64,222,cmp.internal_types[RT_I64]);
    second_misc=COCMiscNew(cc,CMT_LABEL);second_misc->use_cnt=9;
    boundary=cc->coc.coc_next;
    MemCpy(&active,&cc->coc,sizeof(CCodeCtrl));MemCpy(&saved,boundary,sizeof(CCodeCtrl));
    MemCpy(&context,&cc->htc,sizeof(context));
    MemSet(&parent,0,sizeof(parent));QueInit(&parent);QueInit(&parent.next_ie);
    MemCpy(&parent_before,&parent,sizeof(parent));
    MemSet(&ctrl,0,sizeof(ctrl));MemCpy(&ctrl_before,&ctrl,sizeof(ctrl));
    cc->aot=&parent;cc->aotc=&ctrl;cc->aot_depth=1;flags=cc->flags;caught=0;
    try { CmpJoin(cc,CMPF_LEX_FIRST|CMPF_ASM_BLK); }
    catch {caught=Fs->except_ch;Fs->catch_except=TRUE;}
    r[0]=caught=='Compiler';r[1]=cc->aot==&parent;
    r[2]=cc->aotc==&ctrl && !MemCmp(&ctrl,&ctrl_before,sizeof(ctrl));
    r[3]=cc->aot_depth==1;r[4]=!MemCmp(&cc->htc,&context,sizeof(context));
    r[5]=!MemCmp(&parent,&parent_before,sizeof(parent));
    r[6]=!MemCmp(&cc->coc,&active,sizeof(active));r[7]=!MemCmp(boundary,&saved,sizeof(saved));
    if(r[6] && r[7]) {
      r[8]=first->ic_data==111 && second->ic_data==222;
      r[9]=first_misc->use_cnt==7 && second_misc->use_cnt==9;
    }
    r[10]=cc->error_cnt>0 && !cc->warning_cnt;r[11]=(cc->flags&mask)==(flags&mask);
    r[14]=cc->flags^flags;
    //Release only the caller-owned control and its code frames through public
    //APIs. This does not repair the join's packet/hash/control ownership.
    while(cc->coc.coc_next) {COCDel(cc,&cc->coc);COCPop(cc);}
    COCDel(cc,&cc->coc);QueRem(cc);CmpCtrlDel(cc);
    Fs->put_doc=old_doc;DocDel(doc);Free(dbg.fix_file_line);dbg.fix_file_line=old_fix;
    r[12]=Fs->data_heap->used_u8s-used;r[13]=Fs->code_heap->used_u8s-code;
  }
  line=MStrPrint("EXPORT join-boundary.bin %X 168\n",rows);JBLog(line);Free(line);
  JBLog("JOIN BOUNDARY DONE\n");Sleep(1000);
}JBCheck;
