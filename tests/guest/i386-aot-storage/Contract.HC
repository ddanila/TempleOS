U0 ASLog(U8 *s){while(*s)OutU8(0xE9,*s++);}
U0 ASCheck()
{
  I64 *r=CAlloc(24*8),used=Fs->data_heap->used_u8s,i,n,flags;
  CCmpCtrl *cc=CmpCtrlNew();
  CAOTCtrl *a=CAlloc(sizeof(CAOTCtrl));
  CAOT *module=CAlloc(sizeof(CAOT));
  CAOTBinBlk *b,*next;
  CAOTImportExport *ie,*tail;
  CDoc *old=Fs->put_doc,*doc=DocNew;
  U8 *s,*listing,*bytes=CAlloc(32);
  cc->aotc=a;cc->aot=module;QueInit(&module->next_ie);
  a->bin=CAlloc(sizeof(CAOTBinBlk));
  AOTStoreCodeU8(cc,0xAB);AOTStoreCodeU32(cc,0x89ABCDEF);
  AOTStoreCodeU64(cc,0xFEDCBA9876543210);
  r[0]=a->rip==13 && a->num_bin_U8s==13;
  r[1]=a->bin->body[0]==0xAB;
  r[2]=!MemCmp(a->bin->body+1,"\xEF\xCD\xAB\x89\x10\x32\x54\x76\x98\xBA\xDC\xFE",12);
  a->rip=AOT_BIN_BLK_SIZE-4;AOTStoreCodeU32(cc,0x44332211);
  r[3]=a->rip==AOT_BIN_BLK_SIZE && !a->bin->next && a->num_bin_U8s==a->rip;
  a->rip=AOT_BIN_BLK_SIZE-2;AOTStoreCodeU32(cc,0x88776655);
  r[4]=a->rip==AOT_BIN_BLK_SIZE+2 && a->bin->next && !a->bin->next->next;
  r[5]=a->bin->body[AOT_BIN_BLK_SIZE-2]==0x55 && a->bin->body[AOT_BIN_BLK_SIZE-1]==0x66 && a->bin->next->body[0]==0x77 && a->bin->next->body[1]==0x88;
  a->rip=2*AOT_BIN_BLK_SIZE-8;AOTStoreCodeU64(cc,0xFFEEDDCCBBAA9988);
  r[6]=a->rip==2*AOT_BIN_BLK_SIZE && !a->bin->next->next;
  a->rip=2*AOT_BIN_BLK_SIZE-3;AOTStoreCodeU64(cc,0x0123456789ABCDEF);
  b=a->bin->next->next;
  r[7]=b && a->rip==2*AOT_BIN_BLK_SIZE+5 && !b->next;
  r[8]=!MemCmp(a->bin->next->body+AOT_BIN_BLK_SIZE-3,"\xEF\xCD\xAB",3) && !MemCmp(b->body,"\x89\x67\x45\x23\x01",5);
  a->rip=19;AOTStoreCodeU8At(cc,4*AOT_BIN_BLK_SIZE-1,0x1AA,-1,0x123);
  b=b->next;
  r[9]=b && b->next && !b->next->next && a->rip==19 && a->num_bin_U8s==4*AOT_BIN_BLK_SIZE+2;
  r[10]=b->body[AOT_BIN_BLK_SIZE-1]==0xAA && b->next->body[0]==0xFF && b->next->body[1]==0x23;
  r[11]=TRUE;for(i=0;i<AOT_BIN_BLK_SIZE-1;i++)if(b->body[i])r[11]=FALSE;
  AOTStoreCodeU8At(cc,0,0xCC);AOTStoreCodeU8(cc,0xDD);
  r[12]=a->rip==20 && a->num_bin_U8s==4*AOT_BIN_BLK_SIZE+2 && a->bin->body[0]==0xCC && a->bin->body[19]==0xDD;
  Fs->put_doc=doc;a->lst=TRUE;a->lst_col=24;
  AOTStoreCodeU8(cc,0x12);AOTStoreCodeU32(cc,0x89ABCDEF);AOTStoreCodeU64(cc,0xFEDCBA9876543210);
  r[13]=a->lst_col==29;
  AOTStoreCodeU8At(cc,1,0);r[14]=a->lst_col==29;
  AOTStoreCodeU8(cc,0x34);r[15]=a->lst_col==3;
  a->lst=FALSE;Fs->put_doc=old;doc->flags|=DOCF_NO_CURSOR;listing=DocSave(doc,&n);DocDel(doc);
  r[16]=!StrCmp(listing,"\n12 89ABCDEF FEDCBA9876543210 \n34 ");
  flags=cc->flags;cc->flags=0;PrsI386DataRange(cc,7,4);
  cc->flags=CCF_TARGET_I386;PrsI386DataRange(cc,7,4);
  cc->flags=CCF_AOT_COMPILE;PrsI386DataRange(cc,7,4);
  cc->flags=CCF_AOT_COMPILE|CCF_TARGET_I386;PrsI386DataRange(cc,7,0);
  r[17]=module->next_ie==&module->next_ie && module->last_ie==&module->next_ie;
  PrsI386DataRange(cc,0x123456789,8);PrsI386DataRange(cc,0xABCDEF012,17);
  ie=module->next_ie;tail=module->last_ie;
  r[18]=ie!=&module->next_ie && ie->next==tail && tail->next==&module->next_ie && tail->last==ie;
  r[19]=ie->type==26 && ie->rip==0x123456789 && ie->flags==8 && !ie->aot && !ie->str && !ie->src_link;
  r[20]=tail->type==26 && tail->rip==0xABCDEF012 && tail->flags==17;
  cc->flags=flags;QueRem(ie);Free(ie);QueRem(tail);Free(tail);
  r[21]=module->next_ie==&module->next_ie && module->last_ie==&module->next_ie;
  MemCpy(bytes,a->bin->body,32);
  b=a->bin;while(b){next=b->next;Free(b);b=next;}
  Free(a);Free(module);cc->aotc=NULL;cc->aot=NULL;CmpCtrlDel(cc);
  // Account for both exported buffers, allocated after the initial heap sample.
  r[22]=Fs->data_heap->used_u8s-used==MSize2(bytes)+MSize2(listing);r[23]=sizeof(I64)==8;
  s=MStrPrint("EXPORT aot-storage.bin %X C0\n",r);ASLog(s);Free(s);
  s=MStrPrint("EXPORT aot-storage-bytes.bin %X 20\n",bytes);ASLog(s);Free(s);
  s=MStrPrint("EXPORT aot-storage-listing.txt %X %X\n",listing,n);ASLog(s);Free(s);
  ASLog("AOT STORAGE DONE\n");Sleep(1000);
}
ASCheck;
