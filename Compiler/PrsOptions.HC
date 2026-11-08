Bool Option(I64 num,Bool val)
{//Set compiler $LK,"Option",A="FI:::/Doc/Options.DD"$ to val.
  return BEqu(&Fs->last_cc->opts,num,val);
}

Bool GetOption(I64 num)
{//Get state of compiler $LK,"option",A="MN:OPTf_ECHO"$.
  return Bt(&Fs->last_cc->opts,num);
}

