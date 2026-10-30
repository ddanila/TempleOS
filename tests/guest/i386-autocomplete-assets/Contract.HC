U0 AutoCompleteAssetsCheck()
{
  U8 *words;I64 size;CDirEntry entry;
  if(!FileFind("C:/Adam/AutoComplete/ACWords.DATA.Z",&entry) || !(entry.attr&0x400))throw('ACWords',TRUE);
  if(!FileFind("C:/Adam/AutoComplete/ACDefs.DATA",&entry) || entry.size!=26381073)throw('ACDefs',TRUE);
  words=FileRead("C:/Adam/AutoComplete/ACWords.DATA.Z",&size);
  if(!words || size!=1253930)throw('ACRead',TRUE);
  if(!FileWrite("C:/ACWordsCopy.DATA",words,size))throw('ACWrite',TRUE);
  Free(words);
}
