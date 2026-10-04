Bool IsRaw()
{//Are we in BLACK & WHITE raw scrn mode?
  return !Bt(&Fs->display_flags,DISPLAYf_NOT_RAW);
}

