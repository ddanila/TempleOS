#help_index "God"
#include "/Adam/God/BibleInitCore.HC"
BibleInit;

public U8 *BibleLine2Verse(I64 line,I64 separate_ch=CH_SPACE)
{//Line number to verse str, Malloc()ed.
//Separate with <SPACE> or ','.  If you pass '%', it uses "%20".
  CDoc *doc;
  CDocEntry *doc_e;
  I64 i=0,cnt=DefineCnt("ST_BIBLE_BOOKS"),start=0,last_start=0;
  U8 *ptr=DefineSub(0,"ST_BIBLE_BOOK_LINES"),*ptr2;
  while (i<=cnt) {
    last_start=start;
    start=Str2I64(ptr);
    if (line<start)
      break;
    i++;
    ptr+=StrLen(ptr)+1;
  }
  if (0<=--i<cnt) {
    doc=DocRead(BIBLE_FILENAME,DOCF_PLAIN_TEXT|DOCF_NO_CURSOR);
    DocGoToLine(doc,line); //one based
    doc_e=doc->cur_entry;
    while (doc_e!=doc && (doc_e->type_u8!=DOCT_TEXT || !*doc_e->tag))
      doc_e=doc_e->next;
    if (doc_e->type_u8==DOCT_TEXT && '0'<=*doc_e->tag<='9') {
      ptr=ptr2=doc_e->tag;
      while ('0'<=*ptr2<='9' || *ptr2==':')
	ptr2++;
      *ptr2=0;
      if (separate_ch=='%')
	ptr=MStrPrint("%Z%%20%s",i,"ST_BIBLE_BOOKS",ptr);
      else
	ptr=MStrPrint("%Z%c%s",i,"ST_BIBLE_BOOKS",separate_ch,ptr);
    } else {
      while (TRUE) {
	doc_e=doc_e->last;
	if (doc_e==doc) {
	  ptr=NULL;
	  break;
	}
	if (doc_e->y+1<last_start) {
	  ptr=MStrPrint("%Z",i,"ST_BIBLE_BOOKS");
	  break;
	}
	if (doc_e->type_u8==DOCT_TEXT && StrLen(doc_e->tag)>=3) {
	  ptr=doc_e->tag+StrLen(doc_e->tag)-1;
	  while (ptr>doc_e->tag && (!('0'<=*(ptr-1)<='9') || *ptr!=':' ||
		!('0'<=*(ptr+1)<='9')))
	    ptr--;
	  ptr--;
	  while (ptr>=doc_e->tag && '0'<=*ptr<='9')
	    ptr--;
	  ptr2=++ptr;
	  if ('0'<=*ptr2++<='9') {
	    while ('0'<=*ptr2<='9')
	      ptr2++;
	    if (*ptr2++==':' && '0'<=*ptr2++<='9') {
	      while ('0'<=*ptr2<='9')
		ptr2++;
	      *ptr2=0;
	      if (separate_ch=='%')
		ptr=MStrPrint("%Z%%20%s",i,"ST_BIBLE_BOOKS",ptr);
	      else
		ptr=MStrPrint("%Z%c%s",i,"ST_BIBLE_BOOKS",separate_ch,ptr);
	      break;
	    }
	  }
	}
      }
    }
    DocDel(doc);
    return ptr;
  } else
    return NULL;
}

public U0 BookLines(CDoc *doc_out=NULL,I64 start,I64 lines,
	U8 *book_filename=BIBLE_FILENAME)
{//Put N line starting at line M into doc.
  CDoc *doc_in;
  CDocEntry *doc_e;
  if (!doc_out) doc_out=DocPut;
  if (doc_out && FileFind(book_filename)) {
    doc_in=DocRead(book_filename,DOCF_PLAIN_TEXT|DOCF_NO_CURSOR);
    DocGoToLine(doc_in,start); //one based
    doc_e=doc_in->cur_entry;
    while (lines>0 && doc_e!=doc_in) {
      if (doc_e->type_u8==DOCT_TEXT)
	DocPrint(doc_out,"%s",doc_e->tag);
      else if (doc_e->type_u8==DOCT_NEW_LINE) {
	DocPutKey(doc_out,'\n');
	lines--;
      }
      doc_e=doc_e->next;
    }
    DocDel(doc_in);
  }
}

public U0 BibleVerse(CDoc *doc_out=NULL,U8 *verse,I64 lines)
{//Put N lines starting at verse str into doc.
  I64 i;
  CDoc *doc_in;
  CDocEntry *doc_e;
  U8 *st,*st2;
  if (!doc_out) doc_out=DocPut;
  if (doc_out && FileFind(BIBLE_FILENAME)) {
    st=StrNew(verse);
    st2=StrNew(verse);
    if (StrOcc(st,','))
      StrLastRem(st,",",st2);
    else
      *st2=0;
    i=DefineMatch(st,"ST_BIBLE_BOOKS",LMF_IGNORE_CASE);
    if (i>=0) {
      i=Str2I64(DefineSub(i,"ST_BIBLE_BOOK_LINES"));
      doc_in=DocRead(BIBLE_FILENAME,DOCF_PLAIN_TEXT|DOCF_NO_CURSOR);
      DocGoToLine(doc_in,i); //one based
      if (*st2) {
	StrCpy(doc_in->find_replace->find_text,st2);
	EdFindNext(doc_in);
      }
      doc_e=doc_in->cur_entry;
      while (lines>0 && doc_e!=doc_in) {
	if (doc_e->type_u8==DOCT_TEXT)
	  DocPrint(doc_out,"%s",doc_e->tag);
	else if (doc_e->type_u8==DOCT_NEW_LINE) {
	  DocPutKey(doc_out,'\n');
	  lines--;
	}
	doc_e=doc_e->next;
      }
      DocDel(doc_in);
    }
    Free(st);
    Free(st2);
  }
}

public CDoc *BibleDoc()
{//Return Bible as DolDoc with trees.
  CDoc	*res=DocRead(BIBLE_FILENAME);
  CDocEntry *doc_e=res->head.next,*doc_e1;
  Bool open_chapter=FALSE;
  U8	*ptr=Define("ST_BIBLE_BOOK_LINES");
  I64	book,book_cnt=DefineCnt("ST_BIBLE_BOOK_LINES")-1,
	chapter,
	line=Str2I64(ptr,,&ptr);
  ptr++;
  for (book=0;book<book_cnt;book++) {
    while (doc_e->y+1<line) {
      doc_e1=doc_e->next;
      DocEntryDel(res,doc_e);
      doc_e=doc_e1;
    }
    res->cur_entry=doc_e;
    res->cur_col=0;
    DocPrint(res,"$$TR,\"%Z\"$$\n$$ID,2$$",book,"ST_BIBLE_BOOKS");
    line=Str2I64(ptr,,&ptr);
    ptr++;
    chapter=1;
    while (doc_e->y+1<line) {
      doc_e1=doc_e->next;
      if (doc_e->type_u8==DOCT_TEXT && StrMatch(":1 ",doc_e->tag)) {
	res->cur_entry=doc_e;
	res->cur_col=0;
	if (open_chapter) {
	  DocPrint(res,"$$ID,-2$$");
	  open_chapter=FALSE;
	}
	DocPrint(res,"$$TR,\"%d\"$$\n$$ID,2$$",chapter++);
	open_chapter=TRUE;
      } else if (chapter==1) {
	doc_e1=doc_e->next;
	DocEntryDel(res,doc_e);
	doc_e=doc_e1;
      }
      doc_e=doc_e1;
    }
    res->cur_entry=doc_e;
    res->cur_col=0;
    if (open_chapter) {
      DocPrint(res,"$$ID,-2$$");
      open_chapter=FALSE;
    }
    DocPrint(res,"$$ID,-2$$");
  }
  while (doc_e!=res) {
    doc_e1=doc_e->next;
    DocEntryDel(res,doc_e);
    doc_e=doc_e1;
  }
  return res;
}

public U0 BibleView()
{//View Bible as DolDoc with trees.
  U8 buf[STR_LEN];
  CDoc *doc=BibleDoc;
  StrPrint(buf,"AL:%d,1",doc);
  Ed(buf);
  DocDel(doc);
}
U0 CtrlAltB(I64)
{
  PopUp("BibleView;");
}
CtrlAltCBSet('B',&CtrlAltB,"Cmd /Bible");
