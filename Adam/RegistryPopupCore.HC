public Bool OneTimePopUp(U8 *_flags,I64 flag_num,U8 *msg)
{//See $LK,"::/Apps/X-Caliber/X-Caliber.HC"$.
  Bool res=FALSE;
  CDoc *doc;
  CDocEntry *doc_e;
  if (!Bt(_flags,flag_num)) {
    doc=DocNew;
    if (msg) DocPrint(doc,"%s",msg);
    doc_e=DocPrint(doc,"\n$$CB,\"Do not show this msg again.\",LE=1$$");
    DocPrint(doc,"$$CM+CX,0,4$$$$BT,\"OKAY\",LE=1$$\n");
    if (PopUpMenu(doc)==1 && doc_e->de_flags&DOCEF_CHECKED_COLLAPSED) {
      LBts(_flags,flag_num);
      res=TRUE;
    }
    DocDel(doc);
  }
  return res;
}

U0 RegOneTimePopUp(I64 flag_num,U8 *msg)
{//You're not supposed to make system pop-up flags, only me.
  if (OneTimePopUp(sys_msg_flags,flag_num,msg))
    RegWrite("Adam/SysMsgFlags","sys_msg_flags[0]=0x%X;\n",
	  sys_msg_flags[0]);
}

