#help_index "DolDoc/Link"

/* See $LK,"TempleOS Link Types",A="MN:ST_LINK_TYPES"$.
"filename"
"FI:filename"
"FA:haystack_filename,needle_anchor_str"
"FF:haystack_filename,needle_str"
"FF:haystack_filename,needle_str:occurnum"
"FL:filename,linenum"
"MN:SymName"
"PI:filename"
"PF:haystack_filename,needle_str"
"PF:haystack_filename,needle_str:occurnum"
"PL:filename,linenum"
"BF:haystack_bible_book,needle_str"
"DN:word"
"DN:word,defnum"
"HI:index"
"AD:code_address_number"

To edit a doc structure already in memory. See $LK,"SpriteEdText",A="MN:SpriteEdText"$().
"AI:doc_address"
"AA:haystack_doc_address,needle_anchor_str"
"AF:haystack_doc_address,needle_str"
"AF:haystack_doc_address,needle_str:occurnum"
"AL:doc_address,linenum"
*/

#include "/Adam/DolDoc/EdLinkTypes.HH"

#include "/Adam/DolDoc/DocEntryLinkCore.HC"

Bool DocFileEd(I64 _type,U8 *filename,
	U8 *needle_str,I64 *_num,I64 edf_dof_flags)
{
  I64 type=_type,flags=0,old_border_src=Fs->border_src;
  CDocEntry *doc_e;
  CDoc *doc;
  Bool old_silent=Bt(&Fs->display_flags,DISPLAYf_SILENT),
	res=FALSE,other_found=FALSE;
  U8 *st1,*st2;
  try {
    switch (type) {
      case LK_PLAIN:
	flags=DOCF_PLAIN_TEXT|DOCF_NO_CURSOR;
      case LK_DOC:
	type=LK_FILE;
	break;
      case LK_DOC_ANCHOR:
	type=LK_FILE_ANCHOR;
	break;
      case LK_PLAIN_FIND:
	flags=DOCF_PLAIN_TEXT|DOCF_NO_CURSOR;
      case LK_DOC_FIND:
	type=LK_FILE_FIND;
	break;
      case LK_PLAIN_LINE:
	flags=DOCF_PLAIN_TEXT|DOCF_NO_CURSOR;
      case LK_DOC_LINE:
	type=LK_FILE_LINE;
	break;
      case LK_BIBLE_FIND:
	flags=DOCF_PLAIN_TEXT|DOCF_NO_CURSOR;
	break;
    }

    flags|=DOCF_ALLOW_UNDO;

    if (LK_DOC<=_type<=LK_DOC_LINE) {
      doc=Str2I64(filename);//See $LK,"SpriteEdText",A="MN:SpriteEdText"$()
      res=TRUE;
    } else {
      st1=StrNew(filename);
      st2=StrNew(filename);
      StrLastRem(st1,"/",st2); //st2 is name without dir
      if (!FileNameChk(st2))
	doc=NULL;
      else {
	Silent;
	if (Bt(&edf_dof_flags,EDf_BAIL)) //if bail, scan parents
	  res=FileFind(filename,,
		FUF_JUST_FILES|FUF_Z_OR_NOT_Z|FUF_SCAN_PARENTS);
	else if (!(res=FileFind(filename,,FUF_JUST_FILES)))
	  other_found=FileFind(filename,,
		FUF_JUST_FILES|FUF_Z_OR_NOT_Z|FUF_SCAN_PARENTS);
	doc=DocRead(filename,flags);
	doc->desc='Edit';
	Silent(old_silent);
	Fs->border_src=BDS_ED_FILENAME_DRV;
      }
      Free(st1);
      Free(st2);
    }
    if (!doc||doc->doc_signature!=DOC_SIGNATURE_VAL)
      res=FALSE;
    else {
      if (Bt(&edf_dof_flags,EDf_COLLAPSE))
	DocCollapse(TRUE,doc);
      else if (Bt(&edf_dof_flags,EDf_UNCOLLAPSE))
	DocCollapse(FALSE,doc);

      if (res || other_found)
	switch (type) {
	  case LK_FILE_LINE:
	    res=DocGoToLine(doc,*_num);
	    break;
	  case LK_FILE_ANCHOR:
	    res=DocAnchorFind(doc,needle_str);
	    break;
	  case LK_FILE_FIND:
	    res=DocFind(doc,,needle_str,*_num);
	    break;
	  case LK_BIBLE_FIND:
	    res=DocFind(doc,*_num,needle_str);
	    break;
	  default:
	    DocCenter(doc);
	}
      *_num=doc->cur_entry->y+1;

      if (edf_dof_flags&EDF_WAS_WRITE)
	res=FALSE;
      if (!(edf_dof_flags&EDF_BAIL)) {
	if (*doc->filename.name)
	  doc->filename.dirc=DirContextNew(doc->filename.name);
	else
	  doc->filename.dirc=NULL;
	if (DocEd(doc,edf_dof_flags|DOF_DONT_HOME)) {
	  DocLock(doc);
	  doc_e=doc->cur_entry;
	  if (doc_e!=doc)
	    DocEntryRun(doc,doc_e,TRUE);
	  DocUnlock(doc);
	  if (!(LK_DOC<=_type<=LK_DOC_LINE)) {
	    DocWrite(doc);
	    if (edf_dof_flags&EDF_WAS_WRITE)
	      res=TRUE;
	  }
	}
	DirContextDel(doc->filename.dirc);
      }
      if (!(LK_DOC<=_type<=LK_DOC_LINE))
	DocDel(doc);
    }
  } catch {
    Silent(old_silent);
    res=FALSE;
  }
  Fs->border_src=old_border_src;
  return res;
}

#include "/Adam/DolDoc/EdLinkCvtCore.HC"

public Bool DocLinkChk(CDoc *doc,U8 *link_st)
{//Check for bad $LK,"Editor Link",A="MN:LK_FILE"$.
  U8 *filename,*st;
  Bool res=FALSE;
  CDirContext *dirc;
  if (link_st) {
    st=FileNameAbs(doc->filename.name);
    dirc=DirContextNew(st);
    Free(st);
    switch (EdLinkCvt(link_st,&filename)) {
      case -1:
	break;
      case LK_FILE_LINE:
      case LK_PLAIN_LINE:
      case LK_FILE:
//We don't check line number
	res=FileFind(filename,,
	      FUF_JUST_FILES|FUF_Z_OR_NOT_Z|FUF_SCAN_PARENTS);
	break;
      case LK_BIBLE_FIND:
	st=StrNew(link_st+3);
	if (StrOcc(st,','))
	  StrLastRem(st,",");
	if (DefineMatch(st,"ST_BIBLE_BOOKS",LMF_IGNORE_CASE)>=0)
	  res=TRUE;
	Free(st);
	break;
      default://TODO: Need to validate HI: and DN:
	if (Ed(link_st,EDF_BAIL))
	  res=TRUE;
    }
    Free(filename);
    DirContextDel(dirc);
  }
  return res;
}

#include "/Adam/DolDoc/DocLinkFileCore.HC"
