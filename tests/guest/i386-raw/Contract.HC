I64 JRContract()
{
  I64 flags=Fs->display_flags,mask=0;
  Bool old_raw=IsRaw,previous;
  previous=Raw(ON);
  if(previous==old_raw && IsRaw)mask|=1;
  if(Raw(ON) && IsRaw)mask|=2;
  if(Raw(OFF) && !IsRaw)mask|=4;
  if(!Raw(OFF) && !IsRaw)mask|=8;
  Raw(old_raw);
  if(Fs->display_flags==flags && IsRaw==old_raw)mask|=16;
  return mask;
}
