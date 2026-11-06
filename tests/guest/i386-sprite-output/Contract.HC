U0 SOLog(U8 *s){while(*s)OutU8(0xE9,*s++);}
U0 SOCheck()
{
  I64 v[6];U8 *sprite,*s;
  CDC *dc=DCNew(1,1);
  CDoc *old=Fs->put_doc,*doc=DocNew;
  CDocEntry *first,*second;
  dc->body[0]=9;sprite=DC2Sprite(dc);
  Fs->put_doc=doc;
  first=Sprite(sprite);
  v[0]=first && first->bin_data && first->bin_data->size==26;
  v[1]=first && first->bin_data && first->bin_data->data!=sprite &&
    !MemCmp(first->bin_data->data,sprite,26);
  second=Sprite(sprite,"$$SP,\"wrapped\",BI=%d$$");
  v[2]=second && second->bin_data && second->bin_data->tag &&
    !StrCmp(second->bin_data->tag,"wrapped");
  v[3]=first && second && first->bin_data!=second->bin_data &&
    first->bin_data->num!=second->bin_data->num &&
    first->bin_data->use_cnt==1 && second->bin_data->use_cnt==1;
  sprite[17]=4;
  v[4]=first && second && first->bin_data->data[17]==9 && second->bin_data->data[17]==9;
  Fs->put_doc=NULL;v[5]=Sprite(sprite)==NULL;Fs->put_doc=old;
  Free(sprite);DCDel(dc);DocDel(doc);
  s=MStrPrint("EXPORT sprite-output.bin %X %X\n",v,sizeof(v));SOLog(s);Free(s);
  SOLog("SPRITE OUTPUT DONE\n");Sleep(1000);
}
