#include "/Kernel/I386/FileRuntime.HH"
Bool I386LoadScalarTypes(CI386Heap *heap,CHashClass **types,CI386FileServices *files,CI386LexIncludeService *includes,CHashClass **roots)
{
  CI386Task *task=I386TaskSelf;
  CCmpCtrl *boundary,*cc;
  U8 *source=0,*name=0;
  I64 size,attr,exception=0;
  U32 irq;
  Bool accepted=FALSE;
  if(!task || !I386CmpTaskOwnerValid(task,heap,task->hash_table) || !types || !files ||
      files->version!=I386_FILE_SERVICES_VERSION || files->bytes!=sizeof(CI386FileServices) ||
      !files->read || !files->control_new) return FALSE;
  boundary=task->last_cc;
  try {
    source=files->read(heap,"C:/Kernel/Types.HH",&size,&attr,&name);
    if(source && name) {
      cc=files->control_new(source,CCF_AOT_COMPILE,name);
      if(cc) {
        source=0; //The new control owns its input, including on parse failure.
        if(I386CmpCtrlEnter(heap,cc)) accepted=I386BootstrapScalars(heap,cc,types,includes);
        else I386CmpCtrlDel(heap,cc);
      }
    }
  } catch {
    exception=task->except_ch; task->catch_except=TRUE;
  }
  if(!I386CmpCtrlUnwind(task,boundary)) accepted=FALSE;
  irq=I386IrqSave;
  if(source && !I386HeapFree(heap,source)) accepted=FALSE;
  if(name && !I386HeapFree(heap,name)) accepted=FALSE;
  I386IrqRestore(irq);
  if(exception && exception!='Compiler' && exception!='OutMem') throw(exception,TRUE);
  if(accepted && roots) accepted=I386ScalarTypesCheck(roots,TRUE);
  return accepted;
}
