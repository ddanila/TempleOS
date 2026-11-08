//Shared array-dimension parsing; includes native root/list traversal.
#include "/Compiler/PrsType.HH"
U0 PrsArrayDimsParseCore(CPrsTypeServices *services,CCmpCtrl *cc,I64 mode,
  CArrayDim *dim,CArrayDim **pending)
{
  CArrayDim *tmpad,*tmpad1;
  I64 j;
  if (mode.u8[1]==PRS1B_FUN_ARG)
    (*services->report)(services->context,cc,0,"No arrays in fun args at ");
  do {
    if ((*services->lex)(services->context,cc)==']' && !dim->next) {
      j=0;
      if (cc->flags&CCF_TARGET_I386 &&
          (mode.u8[1]==PRS1B_NULL || mode.u8[1]==PRS1B_STATIC_LOCAL_VAR)) j=-1;
    }
    else {
      if ((j=(*services->integer_expression)(services->context,cc))<0)
        (*services->report)(services->context,cc,0,"Invalid array size at ");
    }
    *pending=(*services->allocate)(services->context,sizeof(CArrayDim));
    tmpad=*pending;
    tmpad->next=NULL;
    //Start at the real root, not the stack slot holding its pointer.
    tmpad1=dim;
    do {
      tmpad1->total_cnt*=j;
      if (!tmpad1->next) {
        tmpad1->next=tmpad;
        break;
      }
      tmpad1=tmpad1->next;
    } while (tmpad1);
    *pending=NULL;
    tmpad->cnt=j;
    tmpad->total_cnt=1;
    if (cc->token!=']')
      (*services->report)(services->context,cc,0,"Missing ']' at ");
  } while ((*services->lex)(services->context,cc)=='[');
}
U0 PrsArrayDimsCore(CPrsTypeServices *services,CCmpCtrl *cc,I64 mode,CArrayDim *dim)
{//The same parser body supports arena and individually released allocations.
  CArrayDim *tmpad,*pending=NULL;
  dim->next=NULL;dim->cnt=0;dim->total_cnt=1;
  if (cc->token=='[') {
    if(!services->release) {
      //Private frontend allocations already belong to its control lifetime.
      //Do not require another exception record in its exhausted-arena paths.
      PrsArrayDimsParseCore(services,cc,mode,dim,&pending);
    } else {
      try { PrsArrayDimsParseCore(services,cc,mode,dim,&pending); }
      catch {
        //An exception can arrive before or after the newest node is linked.
        while(tmpad=dim->next) {
          dim->next=tmpad->next;
          if(tmpad==pending)pending=NULL;
          (*services->release)(services->context,tmpad);
        }
        if(pending) {
          tmpad=pending;pending=NULL;
          (*services->release)(services->context,tmpad);
        }
        dim->cnt=0;dim->total_cnt=1;
        //Original catch semantics propagate the same exception automatically.
      }
    }
  }
}
