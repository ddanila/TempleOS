U0 Report(U8 *s){while(*s)OutU8(0xE9,*s++);}
Report("REBOOT REFERENCE START\n");
Reboot;
Report("REBOOT RETURNED\n");
