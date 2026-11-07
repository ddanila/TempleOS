#ifndef I386_COMPILE_FRAME_INCLUDED
#define I386_COMPILE_FRAME_INCLUDED
//Included after BackendCore.HC. Allocator callbacks own the temporary ENTER.
class CI386CompileFrame {
  CHashFun function,*previous_fun;
  CIntermediateCode *enter,*result;
  CHashClass *type;
  Bool temporary;
};
U0 I386CompileFrameOpen(CI386Backend *backend,CI386CompileFrame *frame)
{
  CCmpCtrl *cc=backend->cc;
  CIntermediateCode *node;
  U8 *bytes=frame;
  I64 i;
  for(i=0;i<sizeof(CI386CompileFrame);i++)bytes[i]=0;
  frame->previous_fun=cc->htc.fun;
  frame->temporary=!(cc->htc.fun && cc->coc.coc_head.next->ic_code==IC_ENTER);
  if(!frame->temporary) {frame->type=cc->htc.fun->return_class;return;}
  node=frame->enter=(*backend->allocate)(backend->context,sizeof(CIntermediateCode));
  node->ic_code=IC_ENTER;
  node->last=&cc->coc.coc_head;node->next=cc->coc.coc_head.next;
  node->next->last=node;cc->coc.coc_head.next=node;
  for(node=node->next;node!=&cc->coc.coc_head;node=node->next) {
    if(node->ic_code==IC_RETURN_VAL || node->ic_code==IC_RETURN_VAL2)frame->result=node;
    if(node->ic_code==IC_RET)node->ic_code=IC_LEAVE;
  }
  if(!frame->result)throw('Compiler');
  cc->pass=0;
  (*backend->fold)(backend->context,cc);I386RestorePointerAdds(backend);
  (*backend->fold)(backend->context,cc);I386RestorePointerAdds(backend);
  if(frame->result->ic_code==IC_RETURN_VAL) {
    if(!frame->result->t.arg1_tree ||
        !(frame->type=I386ValueClass(backend,frame->result->t.arg1_tree)))throw('Compiler');
  } else {
    //Match OptPass4's RETURN_VAL2 result-type scan, skipping retired nodes.
    frame->type=backend->types[RT_I64];node=frame->result;
    while(node=OptLag1(node))
      if(node->ic_class) {frame->type=I386ValueClass(backend,node);break;}
  }
  frame->function.return_class=frame->result->ic_class=frame->type;
  cc->htc.fun=&frame->function;
}
U0 I386CompileFrameClose(CI386Backend *backend,CI386CompileFrame *frame)
{
  backend->cc->htc.fun=frame->previous_fun;
  if(frame->enter) {
    frame->enter->last->next=frame->enter->next;
    frame->enter->next->last=frame->enter->last;
    (*backend->release)(backend->context,frame->enter);
    frame->enter=NULL;
  }
}
#endif
