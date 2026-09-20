//Same selection contract for original x64 functions and native retained bindings.
//Only the fields consumed by these queries are initialized; these are not editors.
I64 DocAccessCheck(CDoc *(*put)(CTask *task),CDoc *(*display)(CTask *task),
  CDoc *(*border)(CTask *task))
{
  CTask task,parent;
  CDoc a,b,c;
  if((*put)(0)!=(*put)(Fs) || (*display)(0)!=(*display)(Fs) ||
      (*border)(0)!=(*border)(Fs)) return -1;
  task.task_flags=0; task.parent_task=&parent;
  task.put_doc=task.display_doc=task.border_doc=0;
  parent.task_flags=0; parent.parent_task=0;
  parent.put_doc=parent.display_doc=parent.border_doc=0;
  if((*put)(&task) || (*display)(&task) || (*border)(&task)) return -2;
  a.doc_signature=b.doc_signature=c.doc_signature=DOC_SIGNATURE_VAL;
  task.put_doc=&a; task.display_doc=&b; task.border_doc=&c;
  if((*put)(&task)!=&a || (*display)(&task)!=&b || (*border)(&task)!=&c) return -3;
  a.doc_signature=0;
  if((*put)(&task) || (*display)(&task)!=&b || (*border)(&task)!=&c) return -4;
  a.doc_signature=DOC_SIGNATURE_VAL; b.doc_signature=0;
  if((*put)(&task)!=&a || (*display)(&task) || (*border)(&task)!=&c) return -5;
  b.doc_signature=DOC_SIGNATURE_VAL; c.doc_signature=0;
  if((*put)(&task)!=&a || (*display)(&task)!=&b || (*border)(&task)) return -6;
  c.doc_signature=DOC_SIGNATURE_VAL;
  task.put_doc=&c; parent.put_doc=&a; parent.display_doc=&c; parent.border_doc=&b;
  task.task_flags=1<<TASKf_INPUT_FILTER_TASK;
  parent.task_flags=1<<TASKf_INPUT_FILTER_TASK; //Forward exactly one level.
  if((*put)(&task)!=&a || (*display)(&task)!=&b || (*border)(&task)!=&c) return -7;
  a.doc_signature=0;
  if((*put)(&task) || (*display)(&task)!=&b || (*border)(&task)!=&c) return -8;
  return 8;
}
