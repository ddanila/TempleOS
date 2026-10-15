public I64 PopUpMenu(CDoc *doc,I64 dof_flags=0)
{//Run menu chooser doc in PopUp win task.
  doc->flags|=DOCF_SIZE_MIN | DOCF_FORM;
  return PopUpPrint("DocMenu(0x%X,0x%X);",doc,dof_flags);
}

