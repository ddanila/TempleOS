U0 MLLog(U8 *s){while(*s)OutU8(0xE9,*s++);}
CMemberLst *MLMember(U8 *name)
{
  CMemberLst *member=CAlloc(sizeof(CMemberLst));member->str=name;return member;
}
CMemberLstMeta *MLMeta(U8 *name,I64 value)
{
  CMemberLstMeta *meta=CAlloc(sizeof(CMemberLstMeta));meta->str=name;meta->user_data=value;return meta;
}
U0 MLCheck()
{
  I64 mask=0,used=Fs->data_heap->used_u8s,code_used=Fs->code_heap->used_u8s,*result;U8 *s;
  CHashClass *empty=CAlloc(sizeof(CHashClass)),*base=CAlloc(sizeof(CHashClass)),*derived=CAlloc(sizeof(CHashClass));
  CMemberLst *root=MLMember("M"),*left=MLMember("Z"),*right=MLMember("A"),*outer=MLMember("B"),*shadow=MLMember("B");
  CMemberLstMeta *number=MLMeta("number",0x1122334455667788),*zero=MLMeta("zero",0);
  CMemberLstMeta *text=MLMeta("text","%2d"),*floating=MLMeta("floating",0),*duplicate=MLMeta("number",2);
  F64 value;
  root->left=left;root->right=right;root->next=right;right->next=left;left->next=shadow;
  derived->member_lst_and_root=root;derived->member_cnt=4;derived->base_class=base;
  base->member_lst_and_root=outer;base->member_cnt=1;
  root->flags=0x1234;root->reg=-1;root->pad=0x5A;root->offset=0x1122334455667788;root->size=91;
  if(!MemberFind("missing",empty) && !MemberFind("missing",derived))mask|=1;
  if(MemberFind("M",derived)==root)mask|=2;
  if(MemberFind("Z",derived)==left)mask|=4;
  if(MemberFind("A",derived)==right)mask|=8;
  if(MemberFind("B",derived)==outer)mask|=16;
  right->left=shadow;
  if(MemberFind("B",derived)==shadow && outer->use_cnt==1)mask|=32;
  if(root->use_cnt==1 && left->use_cnt==1 && right->use_cnt==1 && shadow->use_cnt==1 &&
      root->flags==0x1234 && root->reg==-1 && root->pad==0x5A &&
      root->offset==0x1122334455667788 && root->size==91)mask|=64;
  root->use_cnt=0xFFFFFFFF;
  if(MemberFind("M",derived)==root && !root->use_cnt && root->flags==0x1234 &&
      root->reg==-1 && root->pad==0x5A && root->offset==0x1122334455667788)mask|=128;
  root->meta=number;number->next=zero;zero->next=text;text->next=floating;floating->next=duplicate;
  text->flags=MLMF_IS_STR;floating->user_data(F64)=54.2;
  if(MemberMetaData("number",root)==0x1122334455667788 && MemberMetaFind("number",root)==number)mask|=256;
  if(!MemberMetaData("zero",root) && MemberMetaFind("zero",root)==zero &&
      !MemberMetaData("missing",root) && !MemberMetaFind("missing",root) &&
      !MemberMetaFind("Number",root))mask|=512;
  value(I64)=MemberMetaData("floating",root);
  if(!StrCmp(MemberMetaData("text",root),"%2d") && value==54.2 &&
      MemberMetaFind("floating",root)==floating && !root->use_cnt && number->next==zero &&
      floating->next==duplicate && !duplicate->next)mask|=1024;
  Free(number);Free(zero);Free(text);Free(floating);Free(duplicate);
  Free(root);Free(left);Free(right);Free(outer);Free(shadow);Free(empty);Free(base);Free(derived);
  if(Fs->data_heap->used_u8s==used && Fs->code_heap->used_u8s==code_used)mask|=2048;
  result=MAlloc(8);*result=mask;
  s=MStrPrint("EXPORT member-lookup-mask.bin %X 8\n",result);MLLog(s);Free(s);
  MLLog("MEMBER LOOKUP DONE\n");Sleep(1000);
}
MLCheck;
