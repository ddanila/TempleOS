U0 LGOut(U8 *s) {while(*s)OutU8(0xE9,*s++);}
U0 LGCancelProbe()
{
  U8 *old_draw=Fs->draw_it,*data;
  CTaskSettings *old_settings=Fs->next_settings;
  LGOut("LOGIC cancellation ready\n");
  DigitalLogic;
  if (Fs->draw_it!=old_draw || Fs->next_settings!=old_settings)
    LGOut("FAIL Logic cancellation caller state\n");
  data=DocSave(DocPut);
  if (!StrFind("No table specified, aborting.",data))
    LGOut("FAIL Logic cancellation message\n");
  Free(data);
  LGOut("LOGIC cancellation returned\n");
}
