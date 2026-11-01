//Original DocPutKey page traversal; caller holds the document lock.
U0 DocKeyPageCore(CDoc *doc,I64 sc,Bool down)
{
  CDocEntry *doc_ce=doc->cur_entry;
  I64 i;
  if (down) {
    i=doc_ce->y+doc->win_task->win_height-1;
    if (doc_ce->type_u8==DOCT_HEX_ED)
      i+=doc->cur_col/3/doc_ce->hex_ed_width;
    while (doc_ce!=doc &&
          (doc_ce->type_u8!=DOCT_HEX_ED && doc_ce->y<i ||
          doc_ce->type_u8==DOCT_HEX_ED &&
          doc_ce->y+doc->cur_col/3/doc_ce->hex_ed_width<i)) {
      EdLineDown(doc,sc);
      //Paranoid check for stuck on same node.
      if (doc->cur_entry==doc_ce && doc_ce->type_u8!=DOCT_HEX_ED)
        break;
      doc_ce=doc->cur_entry;
    }
  } else {
    i=doc_ce->y-(doc->win_task->win_height-1);
    if (doc_ce->type_u8==DOCT_HEX_ED)
      i+=doc->cur_col/3/doc_ce->hex_ed_width;
    while (doc_ce->last!=doc &&
          (doc_ce->type_u8!=DOCT_HEX_ED && doc_ce->y>i ||
          doc_ce->type_u8==DOCT_HEX_ED &&
          doc_ce->y+doc->cur_col/3/doc_ce->hex_ed_width>i) &&
          doc_ce->y!=doc->head.next->y) {
      EdLineUp(doc,sc);
      //Paranoid check for stuck on same node.
      if (doc->cur_entry==doc_ce && doc_ce->type_u8!=DOCT_HEX_ED)
        break;
      doc_ce=doc->cur_entry;
    }
  }
}
