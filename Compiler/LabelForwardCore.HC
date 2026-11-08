#ifndef OPT_LABEL_IMPL
#define OPT_LABEL_IMPL OptLabelFwd
#endif
CCodeMisc *OPT_LABEL_IMPL(CCodeMisc *lb)
{
  CCodeMisc *lb1;
  while (lb1=lb->fwd)
    lb=lb1;
  return lb;
}
