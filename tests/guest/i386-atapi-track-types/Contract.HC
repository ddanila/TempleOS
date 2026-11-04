U0 ATAPITrackTypesContract()
{
  U8 data[48];
  I64 i;
  CATAPITrack *t=data;
  if(sizeof(CATAPITrack)!=48)throw('ATAPI',TRUE);
  for(i=0;i<48;i++)data[i]=i;
  if(t->track_info_len!=0x0100||t->track_lo!=2||t->session_lo!=3)throw('ATAPI',TRUE);
  if(t->misc1!=0x0605||t->misc2!=7)throw('ATAPI',TRUE);
  if(t->track_start!=0x0B0A0908||t->next_writable!=0x0F0E0D0C)throw('ATAPI',TRUE);
  if(t->free_blks!=0x13121110||t->fixed_packet_size!=0x17161514)throw('ATAPI',TRUE);
  if(t->blocking_factor!=t->fixed_packet_size)throw('ATAPI',TRUE);
  if(t->track_size!=0x1B1A1918||t->rzone_end!=t->track_size)throw('ATAPI',TRUE);
  if(t->last_recorded!=0x1F1E1D1C||t->track_hi!=32||t->session_hi!=33)throw('ATAPI',TRUE);
  if(t->read_compatibility!=0x27262524||t->next_layer_jmp!=0x2B2A2928)throw('ATAPI',TRUE);
  if(t->last_layer_jmp!=0x2F2E2D2C)throw('ATAPI',TRUE);
}
ATAPITrackTypesContract;
