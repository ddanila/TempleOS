U0 GetOutOfDollar()
{//If a $$ has been printed, print another $$ to exit mode.
  CDoc *doc;
  if (IsRaw) {
    if (text.raw_flags&RWF_IN_DOLLAR)
      '$$';
  } else {
    if (fp_doc_put && (doc=(*fp_doc_put)(Fs)) && doc->flags&DOCF_IN_DOLLAR)
      '$$';
  }
}

