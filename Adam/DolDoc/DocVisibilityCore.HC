//Original document visibility controls.
public Bool DocCursor(Bool show=OFF,CDoc *doc=NULL)
{//Show or hide cursor.
  if (!doc && !(doc=DocPut))
    return FALSE;
  return !LBEqu(&doc->flags,DOCf_HIDE_CURSOR,!show);
}

public Bool DocHighlightCursor(Bool show=OFF,CDoc *doc=NULL)
{//Highlight or Don't highlight cursor.
  if (!doc && !(doc=DocPut))
    return FALSE;
  return !LBEqu(&doc->flags,DOCf_DONT_HIGHLIGHT_CURSOR,!show);
}

public Bool DocScroll(Bool val=OFF,CDoc *doc=NULL)
{//Turn scroll bars OFF/ON.
  if (!doc && !(doc=DocPut))
    return FALSE;
  return !LBEqu(&doc->flags,DOCf_NO_SCROLL_BARS,!val);
}

