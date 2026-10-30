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

#include "/Adam/DolDoc/DocFileEdCore.HC"

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
