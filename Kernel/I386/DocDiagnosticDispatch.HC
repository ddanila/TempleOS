#include "/Kernel/I386/DocDiagnosticContext.HH"
class CNativeDocDiagnosticStage {
  CI386Task *owner;
  U0 (*previous_cleanup)(CI386Task *task);
  U8 *image;
  I64 image_bytes;
  CDoc *clipboard;
  CI386DocDiagnosticServices services;
  CI386DocDiagnosticContext context;
};
CNativeDocDiagnosticStage *native_doc_diagnostic_stage;
extern U0 NativeDocDiagnosticCleanup(CI386Task *task);
Bool NativeDocDiagnosticRelease(CNativeDocDiagnosticStage *stage)
{//No cleanup callback points into the temporary diagnostic image.
  if(!stage || native_doc_diagnostic_stage!=stage ||
      stage->owner->cleanup!=&NativeDocDiagnosticCleanup)return FALSE;
  NativeDocAllocArm(0);
  DocDel(stage->clipboard);stage->clipboard=NULL;
  if(stage->image) {
    if(!I386HeapFree(console_config->heap,stage->image))return FALSE;
    stage->image=NULL;KernelLog("DOC DIAGNOSTIC unloaded\n");
  }
  stage->owner->cleanup=stage->previous_cleanup;
  native_doc_diagnostic_stage=NULL;
  return I386HeapFree(console_config->heap,stage);
}
U0 NativeDocDiagnosticCleanup(CI386Task *task)
{
  CNativeDocDiagnosticStage *stage=native_doc_diagnostic_stage;
  U0 (*previous)(CI386Task *task);
  if(!stage || stage->owner!=task)KernelStop;
  previous=stage->previous_cleanup;
  if(!NativeDocDiagnosticRelease(stage))KernelStop;
  if(previous)(*previous)(task);
}
Bool NativeDocDiagnosticCopy(CDoc *doc,Bool clear)
{
  CNativeDocDiagnosticStage *stage=native_doc_diagnostic_stage;
  CDoc *saved=native_clip_doc;
  Bool result=FALSE;
  U32 irq=I386IrqSave;
  if(!stage || stage->owner!=I386TaskSelf)goto copy_done;
  native_clip_doc=stage->clipboard;
  try {result=NativeDocClipCopy(doc,clear);}
  catch {stage->clipboard=native_clip_doc;native_clip_doc=saved;I386IrqRestore(irq);}
  stage->clipboard=native_clip_doc;native_clip_doc=saved;
copy_done:
  I386IrqRestore(irq);return result;
}
Bool NativeDocDiagnosticPaste(CDoc *doc)
{
  CNativeDocDiagnosticStage *stage=native_doc_diagnostic_stage;
  CDoc *saved=native_clip_doc;
  Bool result=FALSE;
  U32 irq=I386IrqSave;
  if(!stage || stage->owner!=I386TaskSelf)goto paste_done;
  native_clip_doc=stage->clipboard;
  try {result=NativeDocClipPaste(doc);}
  catch {stage->clipboard=native_clip_doc;native_clip_doc=saved;I386IrqRestore(irq);}
  stage->clipboard=native_clip_doc;native_clip_doc=saved;
paste_done:
  I386IrqRestore(irq);return result;
}
public I64 DocAllocationCheck()
{
  CNativeDocDiagnosticStage *stage;
  CI386DocDiagnosticContext *context;
  U32 irq=I386IrqSave;
  I64 result=-1;
  if(!console_config || !console_config->doc_diagnostic_load ||
      native_doc_diagnostic_stage) {I386IrqRestore(irq);return -1;}
  stage=I386HeapAlloc(console_config->heap,sizeof(CNativeDocDiagnosticStage),TRUE);
  if(!stage) {I386IrqRestore(irq);return -1;}
  stage->owner=I386TaskSelf;stage->previous_cleanup=stage->owner->cleanup;
  native_doc_diagnostic_stage=stage;stage->owner->cleanup=&NativeDocDiagnosticCleanup;
  context=&stage->context;
  context->version=I386_DOC_DIAGNOSTIC_VERSION;context->bytes=sizeof(CI386DocDiagnosticContext);
  context->globals=&doldoc;context->clipboard=&stage->clipboard;
  context->alloc_count=&native_doc_alloc_count;
  context->alloc=&NativeDocMAlloc;context->calloc=&NativeDocCAlloc;
  context->free=&Free;context->str_new=&StrNew;context->str_cmp=&StrCmp;
  context->doc_new=&DocNew;context->doc_del=&DocDel;context->put_key=&DocPutKey;
  context->ins_entry=&DocInsEntry;context->save=&NativeDocRecordSaveCore;
  context->load=&NativeDocRecordLoadCore;context->write=&DocWrite;context->read=&DocRead;
  context->arm=&NativeDocAllocArm;context->copy_clip=&NativeDocDiagnosticCopy;
  context->paste_clip=&NativeDocDiagnosticPaste;
  I386IrqRestore(irq);
  try {
    if((*console_config->doc_diagnostic_load)(&stage->services,&stage->image,&stage->image_bytes))
      result=(*stage->services.run)(context,sizeof(CI386DocDiagnosticContext));
  } catch {
    if(!NativeDocDiagnosticRelease(stage))KernelStop;
  }
  if(!NativeDocDiagnosticRelease(stage))KernelStop;
  return result;
}
