I64 TGValue;
I64 TGContract(I64 drive)
{
  I64 mask=0;Bool silent=Silent(TRUE);CDoc *doc=DocNew,*disk;
  CDocEntry *tree,*start,*end;U8 *path=MStrPrint("%c:/TreeFixture.DD",drive),*line;
  TGDelete(path);
  if(!DocTreeFind(doc,"App/Leaf",&tree,&start,&end)&&tree==doc&&start==doc&&end==doc)mask|=1;
  if(DocTreeMake(doc,"App/Leaf")&&DocTreeFind(doc,"App/Leaf",&tree,&start,&end)&&
      tree!=doc&&start!=doc&&end!=doc&&!DocTreeMake(doc,"App/Leaf"))mask|=2;
  if(DocTreeWrite(doc,"App/Leaf",FALSE,"TGValue=11;\n"))mask|=4;
  TGValue=0;DocTreeExe(doc,"App/Leaf");if(TGValue==11)mask|=8;
  if(DocTreeAppend(doc,"App/Leaf",FALSE,"TGValue+=7;\n")) {
    TGValue=0;DocTreeExe(doc,"App/Leaf");if(TGValue==18)mask|=16;
  }
  if(DocTreeMake(doc,"App/Other")&&DocTreeFind(doc,"App/Other")&&
      DocTreeFind(doc,"App/Leaf")&&!DocTreeFind(doc,"App/Missing"))mask|=32;
  disk=DocNew(path);if(DocWrite(disk)) {
    DocDel(disk);disk=NULL;
    DocTreeFWrite(path,"Disk/Node","TGValue=25;\n");
    if(DocTreeFFind(path,"Disk/Node")) {
      DocTreeFAppend(path,"Disk/Node","TGValue+=3;\n");
      TGValue=0;DocTreeFExe(path,"Disk/Node");if(TGValue==28)mask|=64;
    }
  }
  if(disk)DocDel(disk);
  DocDel(doc);if(TGDelete(path))mask|=128;Free(path);Silent(silent);
  line=MStrPrint("DOC TREE MASK %d\n",mask);Report(line);Free(line);return mask;
}
I64 TGCheck(I64 drive){I64 v=TGContract(drive);if(v!=255)throw('DocTree',TRUE);return v;}
