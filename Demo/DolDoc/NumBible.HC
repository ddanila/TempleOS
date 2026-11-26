//  This makes a new Bible file
//with line numbers.

U0 NumBibleDocument()
{
  CDoc *doc_in=DocRead("::/Misc/Bible.TXT.Z",DOCF_PLAIN_TEXT_TABS),
	*doc_out=DocNew("~/DemoNumBible.DD.Z");
  CDocEntry *doc_e=doc_in->head.next;
  while (doc_e!=doc_in) {
    if (doc_e->type_u8==DOCT_TEXT) {
      DocPrint(doc_out,"%05d %s",doc_e->y+1,doc_e->tag);
      doc_e=doc_e->next;
      if (doc_e->type_u8==DOCT_NEW_LINE) {
	DocPrint(doc_out,"\n");
	doc_e=doc_e->next;
      }
    } else if (doc_e->type_u8==DOCT_NEW_LINE) {
      DocPrint(doc_out,"%05d\n",doc_e->y+1);
      doc_e=doc_e->next;
    } else
      doc_e=doc_e->next;
  }
  doc_out->flags|=DOCF_NO_CURSOR;
  DocWrite(doc_out);
  DocDel(doc_out);
  DocDel(doc_in);
}

Bool NumBiblePlain(U8 *input,I64 size)
{//Number plain LF-delimited text without building two large DolDoc trees.
  I64 i,start=0,row=1,width=5,next_width=100000,extra=0,offset=0,length;
  U8 *output;
  if (!size || input[size-1]!='\n')
    return FALSE;
  for (i=0;i<size;i++)
    if (input[i]=='\n') {
      if (row==next_width) {
	width++;
	next_width*=10;
      }
      extra+=width;
      if (i>start)
	extra++;
      start=i+1;
      row++;
    } else if (input[i]<' ' || input[i]>'~' || input[i]==0x24)
      return FALSE;

  output=MAlloc(size+extra+1);
  start=0;
  row=1;
  for (i=0;i<size;i++)
    if (input[i]=='\n') {
      StrPrint(output+offset,"%05d",row);
      row++;
      offset+=StrLen(output+offset);
      length=i-start;
      if (length) {
	output[offset]=' ';
	offset++;
	MemCpy(output+offset,input+start,length);
	offset+=length;
      }
      output[offset]='\n';
      offset++;
      start=i+1;
    }
  FileWrite("~/DemoNumBible.DD.Z",output,offset);
  Free(output);
  return TRUE;
}

U0 NumBible()
{
  I64 size;
  U8 *input=FileRead("::/Misc/Bible.TXT.Z",&size);
  Bool numbered=FALSE;
  if (input) {
    numbered=NumBiblePlain(input,size);
    Free(input);
  }
  if (!numbered)
    NumBibleDocument;
}

NumBible;
