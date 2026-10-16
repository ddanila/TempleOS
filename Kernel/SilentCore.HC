Bool Silent(Bool val=ON)
{//Turn-off StdOut console text. (Not sound.)
  return LBEqu(&Fs->display_flags,DISPLAYf_SILENT,val);
}

Bool IsSilent()
{//Return StdOut turned-off?
  return Bt(&Fs->display_flags,DISPLAYf_SILENT);
}

