#help_index "DolDoc/Task;StdOut/Task"
public CDoc *DocPut(CTask *task=NULL)
{//Current document that StdOut Put() goes to.
//Basically, StdOut unless double buffering.
  CDoc *res;
  if (!task) task=Fs;
  if (Bt(&task->task_flags,TASKf_INPUT_FILTER_TASK))
    task=task->parent_task;
  if ((res=task->put_doc) && res->doc_signature==DOC_SIGNATURE_VAL)
    return res;
  else
    return NULL;
}

public CDoc *DocDisplay(CTask *task=NULL)
{//StdOut displayed unless double buffering.
  CDoc *res;
  if (!task) task=Fs;
  if ((res=task->display_doc) && res->doc_signature==DOC_SIGNATURE_VAL)
    return res;
  else
    return NULL;
}

public CDoc *DocBorder(CTask *task=NULL)
{//Doc holding border of window text.
  CDoc *res;
  if (!task) task=Fs;
  if ((res=task->border_doc) && res->doc_signature==DOC_SIGNATURE_VAL)
    return res;
  else
    return NULL;
}

