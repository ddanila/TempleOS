I64 fo_values[10];
U0 FileOccCheck(U8 *root)
{
  CDoc *old=Fs->put_doc,*doc=DocNew;
  U8 *a=MStrPrint("%s/A.TXT",root),*b=MStrPrint("%s/B.TXT",root);
  U8 *cwd=DirCur,*after,*output,*s,*p;
  I64 size,mask=0;
  Bool silent=Silent(FALSE);
  Fs->put_doc=doc;
  fo_values[0]=FileOcc("alpha",a);if(!IsSilent)mask|=1;
  fo_values[1]=FileOcc("alpha",a,"");if(!IsSilent)mask|=2;
  fo_values[2]=FileOcc("alpha",a,"-i");if(!IsSilent)mask|=4;
  fo_values[3]=FileOcc("alpha",a,"+l-i");if(!IsSilent)mask|=8;
  fo_values[4]=FileOcc("alpha",a,"+lb");if(!IsSilent)mask|=16;
  fo_values[5]=FileOcc("alpha",a,"+la");if(!IsSilent)mask|=32;
  fo_values[6]=FileOcc("aa",b,"");if(!IsSilent)mask|=64;
  fo_values[7]=FileOcc("missing",a,"");if(!IsSilent)mask|=128;
  Silent(TRUE);fo_values[8]=FileOcc("alpha",a);if(IsSilent)mask|=256;
  Silent(silent);if(IsSilent==silent)mask|=512;
  output=DocSave(doc,&size);if(!size && Fs->put_doc==doc)mask|=1024;
  after=DirCur;if(!StrCmp(cwd,after))mask|=2048;
  fo_values[9]=mask;
  Fs->put_doc=old;DocDel(doc);Free(output);Free(cwd);Free(after);Free(a);Free(b);
  s=MStrPrint("EXPORT counts.bin %X %X\nFILE OCC DONE\n",fo_values,sizeof(fo_values));
  p=s;while(*p)OutU8(0xE9,*p++);Free(s);
}
