Bool DirNew(CDrv *dv,U8 *cur_dir,CDirEntry *tmpde,Bool free_old_chain=TRUE)
{//Makes a directory entry in the directory from a $LK,"CDirEntry",A="MN:CDirEntry"$ node.
  switch (dv->fs_type) {
    case FSt_REDSEA:
      return RedSeaDirNew(dv,cur_dir,tmpde,free_old_chain);
    case FSt_FAT32:
      return FAT32DirNew(dv,cur_dir,tmpde,free_old_chain);
    default:
      PrintErr("File System Not Supported\n");
      return FALSE;
  }
}

#include "/Kernel/BlkDev/DirTreeDeleteCore.HC"

#include "/Kernel/BlkDev/DirFilesSortCore.HC"

#include "/Kernel/BlkDev/DirFilesFlattenCore.HC"

U0 PutFileLink(U8 *filename,U8 *full_name=NULL,I64 line=0,Bool plain_text=FALSE)
{//Put $LK,"DolDoc",A="FI:::/Doc/DolDocOverview.DD"$ file,line link to StdOut, $LK,"DocPut",A="MN:DocPut"$.
  U8 *st;
  if (!filename) return;
  if (IsRaw) {
    if (line)
      "%s,%04d",filename,line;
    else
      "%s",filename;
  } else {
//LK_DOC,LK_DOC_ANCHOR,LK_DOC_FIND,LK_DOC_LINE
    if (filename[0]=='A'&&filename[2]==':') {
      if (line) //See $LK,"SpriteEdText",A="MN:SpriteEdText"$()
	"$$LK,\"%s,%04d\",A=\"AL:%s,%d\"$$",filename+3,line,filename+3,line;
      else
	"$$LK,\"%s\",A=\"AI:%s\"$$",filename+3,filename+3;
    } else {
      if (!full_name)
	full_name=st=FileNameAbs(filename);
      else
	st=NULL;
      if (plain_text) {
	if (line)
	  "$$LK,\"%s,%04d\",A=\"PL:%s,%d\"$$",filename,line,full_name,line;
	else
	  "$$LK,\"%s\",A=\"PI:%s\"$$",filename,full_name;
      } else {
	if (line)
	  "$$LK,\"%s,%04d\",A=\"FL:%s,%d\"$$",filename,line,full_name,line;
	else
	  "$$LK,\"%s\",A=\"FI:%s\"$$",filename,full_name;
      }
      Free(st);
    }
  }
}

U0 PutDirLink(U8 *dirname,U8 *full_name=NULL)
{//Put $LK,"DolDoc",A="FI:::/Doc/DolDocOverview.DD"$ dir macro to StdOut, $LK,"DocPut",A="MN:DocPut"$.
  U8 *st;
  if (!dirname) return;
  if (IsRaw)
    "%s",dirname;
  else {
    if (!full_name)
      full_name=st=DirNameAbs(dirname);
    else
      st=NULL;
    "$$MA,T=\"%s\",LM=\"Cd(\\\"%s\\\");Dir;\n\"$$",dirname,full_name;
    Free(st);
  }
}
