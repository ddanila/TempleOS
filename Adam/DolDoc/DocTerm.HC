#help_index "DolDoc/Task;StdOut/Task"
#include "/Adam/DolDoc/DocBorderNewCore.HC"

#include "/Adam/DolDoc/DocTermNewCore.HC"

#help_index "DolDoc"

#include "/Adam/DolDoc/TermRightMenuCore.HC"

I64 EdLeftClickLink(CDoc *doc,CDocEntry *doc_e)
{//Called with doc locked, exit unlocked
  Bool res;
  U8 *st;
  if (st=DocEntryLink(doc,doc_e)) {
    DocUnlock(doc);
    if (doc_e->de_flags & DOCEF_POPUP)
      res=PopUpEd(st);
    else
      res=Ed(st);
    Free(st);
    return res;
  }
}

I64 TermRightClickLink(CDoc *doc,CDocEntry *doc_e)
{//Called with doc locked, exit unlocked
  Bool send_new_line=FALSE,res=FALSE;
  U8 *st,*st2;
  I64 i;
  CEdFileName fn;
  if (st2=DocEntryLink(doc,doc_e)) {
    if (st=DocLinkFile(st2)) {
      DocUnlock(doc);
      if ((i=PopUpTermRight(st))>=0) {
	DocBottom(doc);
	switch (i) {
	  case RIGHT_INCLUDE:
	    if (FileExtDot(st) && !FilesFindMatch(st,FILEMASK_JIT)) {
	      if (!PopUpCancelOk(ST_WARN_ST "Not .HC File\n\n")) {
		send_new_line=TRUE;
		break;
	      }
	    }
	    "#include \"%s\";\n$$PT$$$$FG$$$$BG$$",st;
	    WinZBufUpdate;
	    ExeFile(st,CCF_CMD_LINE);
	    res=TRUE;
	    break;
	  case RIGHT_AINCLUDE:
	    if (FileExtDot(st) && !FilesFindMatch(st,FILEMASK_JIT)) {
	      if (!PopUpCancelOk(ST_WARN_ST "Not .HC File\n\n")) {
		send_new_line=TRUE;
		break;
	      }
	    }
	    "Adam(\"#include \\\"%s\\\"\" );\n$$PT$$$$FG$$$$BG$$",st;
	    WinZBufUpdate;
	    AdamFile(st,FALSE);
	    res=TRUE;
	    break;
	  case RIGHT_COPY:
	    StrCpy(fn.name,st);
	    if (DocForm(&fn)) {
	      res=ToBool(Copy(st,fn.name));
	    } else
	      send_new_line=TRUE;
	    break;
	  case RIGHT_MOVE:
	    StrCpy(fn.name,st);
	    if (DocForm(&fn))
	      res=Move(st,fn.name);
	    else
	      send_new_line=TRUE;
	    break;
	  case RIGHT_DELETE:
	    res=ToBool(Del(st));
	    break;
	  case RIGHT_TYPE:
	    res=Type(st);
	    break;
	  case RIGHT_ED:
	    if (FileExtDot(st) && !FilesFindMatch(st,FILEMASK_DD)) {
	      if (!PopUpCancelOk(ST_WARN_ST "Not DolDoc File\n\n")) {
		send_new_line=TRUE;
		break;
	      }
	    }
	    "Ed(\"%s\");\n$$PT$$$$FG$$$$BG$$",st;
	    res=Ed(st);
	    break;
	  case RIGHT_MOUNT:
	    if (FileExtDot(st) && !FilesFindMatch(st,"*.ISO.C")) {
	      if (!PopUpCancelOk(ST_WARN_ST "Not .ISO.C File\n\n")) {
		send_new_line=TRUE;
		break;
	      }
	    }
	    "MountFile(\"%s\");\n$$PT$$$$FG$$$$BG$$",st;
	    WinZBufUpdate;
	    MountFile(st);
	    res=TRUE;
	    break;
	  case RIGHT_PLAIN:
	    "Plain(\"%s\");\n$$PT$$$$FG$$$$BG$$",st;
	    res=Plain(st);
	    break;
	  case RIGHT_INFILE:
	    if (FileExtDot(st) && !FilesFindMatch(st,"*.IN*")) {
	      if (!PopUpCancelOk(ST_WARN_ST "Not .IN File\n\n")) {
		send_new_line=TRUE;
		break;
	      }
	    }
	    "InFile(\"%s\");\n$$PT$$$$FG$$$$BG$$",st;
	    WinZBufUpdate;
	    InFile(st);
	    res=TRUE;
	    break;
	}
      } else
	send_new_line=TRUE;
      Free(st);
    } else
      send_new_line=TRUE;
    Free(st2);
  } else
    send_new_line=TRUE;
  DocBottom(doc);
  "$$PT$$$$FG$$$$BG$$";
  if (send_new_line)
    '\n';
  return res;
}
