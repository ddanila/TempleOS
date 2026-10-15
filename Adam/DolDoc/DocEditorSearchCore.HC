public U0 EdFindNext(CDoc *doc)
{//Editor F3 find next, possibly doing replaces.
  Bool unlock=DocLock(doc);
  U8 *ptr,*ptr2,*ptr3;
  CDocEntry *doc_ce=doc->cur_entry,*doc_e=doc_ce;
  I64 sf_flags;
  if (doc->find_replace->match_case)
    sf_flags=0;
  else
    sf_flags=SFF_IGNORE_CASE;
  if (doc->find_replace->whole_labels)
    sf_flags|=SFG_WHOLE_LABELS;
  do {
    if (doc_e!=doc) {
      if (doc_e->de_flags&DOCEF_TAG && doc_e->tag &&
	    !(doc_e->de_flags&(DOCEG_DONT_EDIT|DOCEF_FILTER_SKIP))) {
	if (doc_e->type & DOCET_SEL ||
	      !doc->find_replace->scan_sel_text) {
	  if (doc->find_replace->scan_fwd) {
	    if (doc_e==doc_ce) {
	      ptr=doc_ce->tag+doc->cur_col+1;
	      if (ptr-doc_ce->tag>=doc_ce->max_col)
		goto fn_skip;
	      if (ptr-doc_ce->tag<doc_ce->min_col)
		ptr=doc_ce->tag+doc_ce->min_col;
	    } else
	      ptr=doc_e->tag;
	    if (ptr=StrFind(doc->find_replace->find_text,ptr,sf_flags)) {
	      doc->cur_entry=doc_e;
	      doc->cur_col=ptr-doc_e->tag;
	      if (doc->cur_col>=doc_e->max_col)
		doc->cur_col=doc_e->max_col-1;
	      if (doc->cur_col<doc_e->min_col)
		doc->cur_col=doc_e->min_col;
	      DocCenter(doc);
	      if (unlock)
		DocUnlock(doc);
	      return;
	    }
	  } else {
	    ptr2=NULL;
	    ptr=doc_e->tag+doc_e->min_col;
	    if (doc_e==doc_ce)
	      ptr3=doc_ce->tag+doc->cur_col;
	    else
	      ptr3=doc_e->tag+doc_e->max_col;
	    while (ptr=StrFind(doc->find_replace->find_text,ptr,sf_flags)) {
	      if (ptr>=ptr3)
		break;
	      ptr2=ptr++;
	    }
	    if (ptr2 && ptr2<ptr3) {
	      doc->cur_entry=doc_e;
	      doc->cur_col=ptr2-doc_e->tag;
	      if (doc->cur_col>=doc_e->max_col)
		doc->cur_col=doc_e->max_col-1;
	      if (doc->cur_col<doc_e->min_col)
		doc->cur_col=doc_e->min_col;
	      DocCenter(doc);
	      if (unlock)
		DocUnlock(doc);
	      return;
	    }
	  }
	}
      }
    }
fn_skip:
    if (doc->find_replace->scan_fwd)
      doc_e=doc_e->next;
    else
      doc_e=doc_e->last;
  } while (doc_e!=doc_ce);
  if (unlock)
    DocUnlock(doc);
}

public U0 EdSelAll(CDoc *doc,Bool sel)
{//Set state of $LK,"DOCET_SEL",A="MN:DOCET_SEL"$ on all entries.
  Bool unlock=DocLock(doc);
  CDocEntry *doc_e=doc->head.next;
  while (doc_e!=doc) {
    BEqu(&doc_e->type,DOCEt_SEL,sel);
    doc_e=doc_e->next;
  }
  if (unlock)
    DocUnlock(doc);
}

public Bool EdFindPaired(CDoc *doc,U8 plus,U8 minus,
Bool fwd,Bool abort_on_dbl_colon=FALSE)
{//Find { } or ( ) pair. Move cur_entry & center.
  Bool unlock=DocLock(doc),res=FALSE;
  U8 *ptr;
  I64 ch,levels=0,colons=0,original_col=doc->cur_col;
  CDocEntry *doc_ce=doc->cur_entry,*doc_e=doc_ce,*original_ce=doc_ce;
  if (abort_on_dbl_colon && EdCurU8(doc)==':')
    colons=1;
  else
    colons=0;
  do {
    if (doc_e!=doc) {
      if (doc_e->de_flags&DOCEF_TAG && doc_e->tag &&
	    !(doc_e->de_flags&DOCEF_FILTER_SKIP)) {
	if (fwd) {
	  if (doc_e==doc_ce)
	    ptr=doc_e->tag+doc->cur_col+1;
	  else
	    ptr=doc_e->tag;
	  if (ptr-doc_e->tag<doc_e->min_col)
	    ptr=doc_e->tag+doc_e->min_col;
	  if (ptr-doc_e->tag>=doc_e->max_col)
	    goto pa_skip;
	  while (ch=*ptr++)
	    if (abort_on_dbl_colon && ch==':') {
	      if (++colons==2) {
		doc->cur_entry=doc_e;
		doc->cur_col=ptr-doc_e->tag-1;
		EdCursorLeft(doc);
		res=FALSE;
		goto pa_done;
	      }
	    } else {
	      colons=0;
	      if (ch==plus)
		levels++;
	      else if (ch==minus) {
		if (!levels--) {
		  doc->cur_entry=doc_e;
		  doc->cur_col=ptr-doc_e->tag-1;
		  res=doc->cur_entry!=original_ce ||
			doc->cur_col!=original_col;
		  goto pa_done;
		}
	      }
	    }
	} else {
	  if (doc_e==doc_ce) {
	    ptr=doc_e->tag+doc->cur_col-1;
	    if (ptr-doc_e->tag>=doc_e->max_col)
	      ptr=doc_e->tag+doc_e->max_col-1;
	  } else
	    ptr=doc_e->tag+doc_e->max_col-1;
	  if (ptr-doc_e->tag<doc_e->min_col)
	    goto pa_skip;
	  while (ptr>=doc_e->tag+doc_e->min_col) {
	    ch=*ptr--;
	    if (abort_on_dbl_colon && ch==':') {
	      if (++colons==2) {
		doc->cur_entry=doc_e;
		doc->cur_col=ptr-doc_e->tag+1;
		res=FALSE;
		goto pa_done;
	      }
	    } else {
	      colons=0;
	      if (ch==plus)
		levels++;
	      else if (ch==minus) {
		if (!levels--) {
		  doc->cur_entry=doc_e;
		  doc->cur_col=ptr-doc_e->tag+1;
		  res=doc->cur_entry!=original_ce ||
			doc->cur_col!=original_col;
		  goto pa_done;
		}
	      }
	    }
	  }
	}
      }
    }
pa_skip:
    if (fwd)
      doc_e=doc_e->next;
    else
      doc_e=doc_e->last;
  } while (doc_e!=doc_ce);
pa_done:
  DocRecalc(doc);
  DocCenter(doc);
  if (unlock)
    DocUnlock(doc);
  return res;
}

public Bool EdGoToFun(CDoc *doc,Bool fwd,Bool abort_on_dbl_colon)
{//Move cur_entry to start of cur fun and center.(Shoddy)
  Bool unlock=DocLock(doc),res=FALSE;
  I64 ch,levels,colons;
  if (fwd) {
    levels=0;
    colons=0;
    while (doc->cur_entry!=doc) {
      ch=EdCurU8(doc);
      if (abort_on_dbl_colon && ch==':') {
	if (++colons==2) {
	  EdCursorLeft(doc);
	  break;
	}
      } else {
	colons=0;
	if (ch=='{')
	  levels++;
	else if (ch=='}' && !levels--)
	  break;
      }
      EdCursorRight(doc);
    }
    DocRecalc(doc);
    if (doc->cur_entry!=doc)
      res=TRUE;
  } else {
    while (EdFindPaired(doc,'}','{',FALSE,abort_on_dbl_colon));
    if (doc->cur_entry!=doc) {
      ch=EdCurU8(doc);
      if (abort_on_dbl_colon && ch==':')
	res=TRUE;
      else {
	if (ch=='{')
	  res=TRUE;
      }
    }
  }
  if (unlock)
    DocUnlock(doc);
  return res;
}

public U0 EdSelFun(CDoc *doc,Bool abort_on_dbl_colon=FALSE)
{//Set $LK,"DOCET_SEL",A="MN:DOCET_SEL"$ on all entries in cur fun.
  Bool unlock=DocLock(doc);
  U8 *ptr;
  I64 ch,levels=0,colons=0;
  CDocEntry *doc_e;
  EdSelAll(doc,FALSE);
  EdGoToFun(doc,FALSE,abort_on_dbl_colon);
  if (EdCurU8(doc)=='{')
    levels--;
  else if (abort_on_dbl_colon && EdCurU8(doc)==':') {
    EdCursorRight(doc);
    if (EdCurU8(doc)==':')
      EdCursorRight(doc);
  }
  doc_e=doc->cur_entry;
  while (doc_e!=doc) {
    doc_e->type|=DOCET_SEL;
    if (doc_e->de_flags&DOCEF_TAG && doc_e->tag) {
      ptr=doc_e->tag;
      if (doc_e==doc->cur_entry)
	ptr+=doc->cur_col;
      while (ch=*ptr++)
	if (abort_on_dbl_colon && ch==':') {
	  if (++colons==2)
	    goto sf_done;
	} else {
	  colons=0;
	  if (ch=='{')
	    levels++;
	  else if (ch=='}' && !levels--)
	    goto sf_done;
	}
    }
    doc_e=doc_e->next;
  }
sf_done:
  DocRecalc(doc);
  if (unlock)
    DocUnlock(doc);
}

