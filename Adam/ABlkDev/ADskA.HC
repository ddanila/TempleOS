#help_index "File/Cmd Line (Typically);Cmd Line (Typically)"
public U8 *DBlk(I64 blk,Bool write=FALSE)
{//Dump disk block. Optionally, write.
//If you set write to TRUE, the block will
  //be written when you press <ESC>.
  //See $LK,"::/Demo/Dsk/DskRaw.HC"$.
  U8 *buf=MAlloc(BLK_SIZE);

  BlkRead(Fs->cur_dv,buf,blk,1);
  DocD(buf,BLK_SIZE);
  if (write) {
    "Edit and press <ESC> to write or <SHIFT-ESC>\n";
    if (View) {
      "Write\n";
      BlkWrite(Fs->cur_dv,buf,blk,1);
    }
  }
  return buf;
}

public U8 *DClus(I64 c,Bool write=FALSE,I64 num=0)
{//Dump disk clus. Optionally, write.
//If you set write to TRUE, the clus will
  //be written when you press <ESC>.
  //See $LK,"::/Demo/Dsk/DskRaw.HC"$.
  //Do $LK,"Dir",A="MN:Dir"$("*",TRUE); to get clus numbers of files.
  U8 *buf=MAlloc(Fs->cur_dv->spc<<BLK_SIZE_BITS);
  c=ClusNumNext(Fs->cur_dv,c,num);
  ClusRead(Fs->cur_dv,buf,c,1);
  "Clus:%X\n",c;
  DocD(buf,Fs->cur_dv->spc<<BLK_SIZE_BITS);
  if (write) {
    "Edit and press <ESC> to write or <SHIFT-ESC>\n";
    if (View) {
      "Write\n";
      ClusWrite(Fs->cur_dv,buf,c,1);
    }
  }
  return buf;
}

public U8 *Dump(U8 *filename,Bool write=FALSE)
{//Dump file. Optionally, write.
//If you set write to TRUE, the file will
  //be written when you press <ESC>.
  U8 *buf;
  I64 size;
  if (buf=FileRead(filename,&size)) {
    DocD(buf,size);
    if (write) {
      "Edit and press <ESC> to write or <SHIFT-ESC>\n";
      if (View) {
	"Write\n";
	FileWrite(filename,buf,size);
      }
    }
  }
  return buf;
}

#include "/Adam/ABlkDev/CopyMoveCore.HC"

#include "/Adam/ABlkDev/CopyTreeCore.HC"

#include "/Adam/ABlkDev/DelTreeCore.HC"

U0 TouchFile(U8 *filename,U8 *attr,CDate cdt=I64_MIN)
{
  CDrv *dv=Let2Drv(*filename);
  CDirEntry de;
  U8 *cur_dir=StrNew(filename),buf[STR_LEN];
  if (FileFind(filename,&de,FUF_JUST_FILES)) {
    Free(de.full_name);
    if (!StrCmp(attr,"+?"))
      "%-48ts %s\n",filename,StrPrintFlags(buf,Define("ST_FILE_ATTRS"),de.attr);
    else {
      StrFirstRem(cur_dir,":");
      StrLastRem(cur_dir,"/");
      if (!*cur_dir)
	StrCpy(cur_dir,"/");
      ScanFlags(&de.attr,Define("ST_FILE_ATTRS"),attr);
      if (cdt==I64_MIN)
	de.datetime=Now;
      else
	de.datetime=cdt;
      DirNew(dv,cur_dir,&de,FALSE);
    }
  } else
    PrintErr("File not found: \"%s\".\n",filename);
  Free(cur_dir);
}
public U0 Touch(U8 *files_find_mask="*",U8 *attr="+?",
	U8 *fu_flags=NULL,CDate cdt=I64_MIN)
{/*Touch file attributes and DateTime.
Default lists attributes.
attr: "+?" =show current
"+T" =resident
$LK,"RS_ATTR_READ_ONLY",A="MN:RS_ATTR_READ_ONLY"$  $LK,"ST_FILE_ATTRS",A="MN:ST_FILE_ATTRS"$
To Set DateL:
Touch(filename,"",,datetime);
*/
  I64 fuf_flags=0;
  CDirEntry *tmpde,*tmpde1;
  ScanFlags(&fuf_flags,Define("ST_FILE_UTIL_FLAGS"),"+f+F");
  ScanFlags(&fuf_flags,Define("ST_FILE_UTIL_FLAGS"),fu_flags);
  tmpde=tmpde1=FilesFind(files_find_mask,fuf_flags);
  while (tmpde) {
    TouchFile(tmpde->full_name,attr,cdt);
    tmpde=tmpde->next;
  }
  DirTreeDel(tmpde1);
}
