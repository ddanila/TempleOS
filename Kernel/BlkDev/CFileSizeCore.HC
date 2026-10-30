I64 FSize(CFile *f)
{//Report size of opened file in bytes.
  if (f)
    return f->de.size;
  else
    return 0;
}

