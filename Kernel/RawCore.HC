Bool Raw(Bool val)
{//Set to direct scrn, BLACK & WHITE, non-windowed output mode.
  if (!val)
    VGAFlush;
  return !LBEqu(&Fs->display_flags,DISPLAYf_NOT_RAW,!val);
}
