#include "/Compiler/I386/Backend.HH"
#include "/Compiler/I386/EmitCore.HC"
U0 I386AsmCore(CI386Backend *backend,CCmpCtrl *cc,CI386Out *out,CAOT *aot,I64 pass)
{
  CAOTImportExport *ie;
  CCodeMisc *label;
  I64 begin=out->count,width,delta;
  U8 *ptr;
  if(!aot || aot->abss || aot->heap_glbls || aot->aot_U8s<0 ||
      (aot->aot_U8s && !aot->buf)) {
    (*backend->report)(backend->context,6,0,0);
    throw('Compiler');
  }
  I386Bytes(out,aot->buf,aot->aot_U8s);
  for(ie=aot->next_ie;ie!=&aot->next_ie;ie=ie->next) {
    width=0;
    if(ie->type==IET_REL_I8) width=1;
    if(ie->type==IET_REL_I16) width=2;
    if(ie->type==IET_REL_I32) width=4;
    if(!width || !ie->str || !(ie->flags&IEF_GOTO_LABEL) ||
        ie->rip<0 || ie->rip>aot->aot_U8s-width ||
        !(label=COCGoToLabelFind(cc,ie->str))) {
      (*backend->report)(backend->context,7,0,0);
      throw('Compiler');
    }
    label=OptLabelFwd(label);
    if(!pass) label->use_cnt++;
    if(pass) {
      ptr=out->data+begin+ie->rip;
      //Unresolved assembler expressions retain their numeric addend in-place.
      if(width==1) delta=*ptr(I8 *);
      else if(width==2) delta=*ptr(I16 *);
      else delta=*ptr(I32 *);
      delta+=label->addr-begin-ie->rip-width;
      if(width==1) {
        if(delta<I8_MIN || delta>I8_MAX) throw('Compiler');
        *ptr(U8 *)=delta;
      } else if(width==2) {
        if(delta<I16_MIN || delta>I16_MAX) throw('Compiler');
        *ptr(U16 *)=delta;
      } else {
        if(delta<I32_MIN || delta>I32_MAX) throw('Compiler');
        *ptr(U32 *)=delta;
      }
    }
  }
}
