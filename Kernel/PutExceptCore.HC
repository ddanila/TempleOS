U0 PutExcept(Bool catch_it=TRUE)
{//Print exception msg and catch exception.
  "Except:%c:",Fs->except_ch;
  "%P:%P:%P:%P:%P:%P\n",Fs->except_callers[0],Fs->except_callers[1],
	Fs->except_callers[2],Fs->except_callers[3],Fs->except_callers[4],
	Fs->except_callers[5],Fs->except_callers[6],Fs->except_callers[7];
  Fs->catch_except=catch_it;
}

