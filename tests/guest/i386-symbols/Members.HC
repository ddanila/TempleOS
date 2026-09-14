I64 MemberLookupTest()
{
  CHashClass classes[2];
  CMemberLst members[5];
  CMemberLstMeta meta[3];
  U8 left[2],right[2];
  I64 i,j,expected;
  left[1]=0; right[1]=0;
  for(i=0;i<256;i++) {
    left[0]=i;
    for(j=0;j<256;j++) {
      right[0]=j; expected=0;
      if(i<j) expected=-1;
      if(i>j) expected=1;
      if(StrCmp(left,right)!=expected) return 10;
    }
  }
  if(StrCmp("prefix","prefix-long")!=-1 || StrCmp("prefix-long","prefix")!=1 ||
      StrCmp("a\x00tail","a") || StrCmp("same","same")) return 11;
  for(i=0;i<5;i++) {
    members[i].left=0; members[i].right=0; members[i].next=0;
    members[i].left_class_base=0; members[i].right_class_base=0;
    members[i].meta=0; members[i].use_cnt=0;
  }
  classes[0].base_class=0; classes[1].base_class=&classes[0];
  classes[0].member_lst_and_root=&members[3];
  classes[1].member_lst_and_root=&members[0];
  members[0].str="m"; members[1].str="z"; members[2].str="a";
  members[3].str="inherited"; members[4].str="m";
  members[0].left=&members[1]; members[0].right=&members[2];
  members[3].left=&members[4];
  if(MemberFind("m",&classes[1])!=&members[0] ||
      MemberFind("z",&classes[1])!=&members[1] ||
      MemberFind("a",&classes[1])!=&members[2] ||
      MemberFind("inherited",&classes[1])!=&members[3] ||
      MemberFind("m",&classes[0])!=&members[4] ||
      MemberFind("missing",&classes[1]) || MemberFind("M",&classes[1])) return 12;
  for(i=0;i<5;i++) if(members[i].use_cnt!=1) return 13;
  members[0].use_cnt=0xFFFFFFFF;
  if(MemberFind("m",&classes[1])!=&members[0] || members[0].use_cnt) return 14;
  classes[1].member_lst_and_root=0;
  if(MemberFind("inherited",&classes[1])!=&members[3]) return 15;
  members[0].meta=meta;
  meta[0].next=&meta[1]; meta[1].next=&meta[2]; meta[2].next=0;
  meta[0].str="limits"; meta[1].str="limits"; meta[2].str="tail";
  meta[0].user_data=0xFEDCBA9876543210; meta[1].user_data=-1; meta[2].user_data=0x100000002;
  if(MemberMetaFind("limits",&members[0])!=&meta[0] ||
      MemberMetaData("limits",&members[0])!=0xFEDCBA9876543210 ||
      MemberMetaFind("tail",&members[0])!=&meta[2] ||
      MemberMetaData("tail",&members[0])!=0x100000002 ||
      MemberMetaFind("missing",&members[0]) || MemberMetaData("missing",&members[0]) ||
      MemberMetaFind("limits",&members[1]) || MemberMetaData("limits",&members[1])) return 16;
  //Synthetic class keys are compared only, never dereferenced.
  members[0].member_class_base=0x80000000;
  members[1].member_class_base=0x7FFFFFF0;
  members[2].member_class_base=0xFFFFFF00;
  members[0].left_class_base=&members[1]; members[0].right_class_base=&members[2];
  classes[1].member_class_base_root=&members[0]; classes[0].member_class_base_root=&members[0];
  if(MemberClassBaseFind(0x80000000,&classes[1])!=&members[0] ||
      MemberClassBaseFind(0x7FFFFFF0,&classes[1])!=&members[1] ||
      MemberClassBaseFind(0xFFFFFF00,&classes[1])!=&members[2] ||
      MemberClassBaseFind(1,&classes[1]) || MemberClassBaseFind(0xFFFFFFFF,&classes[1])) return 17;
  classes[1].member_class_base_root=0;
  if(MemberClassBaseFind(0x80000000,&classes[1])) return 18;
  return 0;
}
