#help_index "DolDoc/Tree"

#include "/Adam/DolDoc/DocTreeCore.HC"

#help_index "DolDoc/Compiler;Compiler"
public I64 ExeDoc(CDoc *doc,I64 ccf_flags=0)
{//JIT Compile and execute a document.
  I64 res;
  Bool okay=TRUE,unlock_doc=DocLock(doc);
  CCmpCtrl *cc=CmpCtrlNew(,ccf_flags|CCF_DONT_FREE_BUF);
  if (Fs->last_cc!=&Fs->next_cc)
    cc->opts=Fs->last_cc->opts;
  QueIns(cc,Fs->last_cc);
  LexAttachDoc(cc,,doc);
  try {
    Lex(cc);
    res=ExeCmdLine(cc);
  } catch {
    if (Fs->except_ch=='Compiler' || Fs->except_ch=='Break') {
      Fs->catch_except=TRUE;
      okay=FALSE;
      res=0;
    }
  }
  QueRem(cc);
  if (okay)
    CmpCtrlDel(cc); //TODO: can crash
  if (unlock_doc)
    DocUnlock(doc);
  return res;
}

#include "/Adam/DolDoc/DocTreeExecCore.HC"
