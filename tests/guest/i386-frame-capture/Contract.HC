U0 GRLog(U8 *s) {while(*s)OutU8(0xE9,*s++);}
U0 GRCheck(U8 *name)
{
  I64 v[12],i,size,packed_size,read_size,file_size;
  CDC *base=DCNew(8,4),*copy,*diff,*loaded;
  U8 *raw,*packed,*file,*s;
  for(i=0;i<32;i++)base->body[i]=i;
  DCDepthBufAlloc(base);
  for(i=0;i<32;i++)base->depth_buf[i]=1000+i;
  copy=DCCopy(base);
  v[0]=copy!=base && copy->body!=base->body && !MemCmp(copy->body,base->body,32);
  v[1]=copy->r!=base->r && !MemCmp(copy->r,base->r,128) &&
    copy->depth_buf!=base->depth_buf && !MemCmp(copy->depth_buf,base->depth_buf,128);
  copy->depth_buf[0]=9;
  v[2]=base->depth_buf[0]==1000 && DCDiff(base,copy)==NULL;
  copy->body[19]=14;diff=DCDiff(base,copy);
  v[3]=diff && diff->x0==3 && diff->y0==2 && diff->width==1 && diff->height==1;
  v[4]=diff && diff->body[0]==14 && diff->body[1]==TRANSPARENT;
  v[5]=base->body[19]==19;
  DCDel(diff);copy->body[0]=13;diff=DCDiff(base,copy);
  v[6]=diff && diff->x0==0 && diff->y0==0 && diff->width==4 && diff->height==3 &&
    diff->body[0]==13 && diff->body[2*diff->width_internal+3]==14;
  DCDel(diff);DCDel(copy);
  base->cdt=0x0102030405060708;base->x0=-2;base->y0=5;
  raw=DCSave(base,&size,0);v[7]=size==64 && raw(CDC *)->flags==0;
  packed=DCSave(base,&packed_size,DCSF_COMPRESSED);loaded=DCLoad(packed,&read_size);
  v[8]=read_size==packed_size && loaded->width==8 && loaded->height==4 &&
    loaded->cdt==base->cdt && !MemCmp(loaded->body,base->body,32);
  DCDel(loaded);Free(packed);
  v[9]=GRWrite(name,base,0)==64;
  file=FileRead(name,&file_size);v[10]=file_size==size && !MemCmp(file,raw,size);Free(file);
  loaded=GRRead(name);
  v[11]=loaded && loaded->width==8 && loaded->height==4 && loaded->cdt==base->cdt &&
    loaded->x0==-2 && loaded->y0==5 && !MemCmp(loaded->body,base->body,32);
  DCDel(loaded);DCDel(base);Del(name);
  s=MStrPrint("EXPORT gr-raw.bin %X %X\n",raw,size);GRLog(s);Free(s);
  s=MStrPrint("EXPORT gr-checks.bin %X %X\n",v,sizeof(v));GRLog(s);Free(s);
  GRLog("FRAME CAPTURE DONE\n");Sleep(1000);Free(raw);
}
