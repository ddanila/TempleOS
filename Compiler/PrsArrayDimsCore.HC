//Shared array-dimension parsing; includes native root/list traversal.
#include "/Compiler/PrsType.HH"
U0 PrsArrayDimsCore(CPrsTypeServices *services,CCmpCtrl *cc,I64 mode,CArrayDim *dim)
{//dim->next!=0 for array
  CArrayDim *tmpad,*tmpad1;
  I64 j;
  dim->next=NULL;
  dim->cnt=0;
  dim->total_cnt=1;
  tmpad1=&dim->next;
  if (cc->token=='[') {
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
      tmpad=(*services->allocate)(services->context,sizeof(CArrayDim));
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
      tmpad1=tmpad;
      tmpad->cnt=j;
      tmpad->total_cnt=1;
      if (cc->token!=']')
	(*services->report)(services->context,cc,0,"Missing ']' at ");
    } while ((*services->lex)(services->context,cc)=='[');
  }
}
