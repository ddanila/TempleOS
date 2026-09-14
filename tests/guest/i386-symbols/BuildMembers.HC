I64 member_diag_errors,member_diag_warnings;
U0 MemberTestDiagnostic(U8 *context,Bool warning)
{
  if(context!=&member_diag_errors) member_diag_errors+=100;
  if(warning) member_diag_warnings++;
  else member_diag_errors++;
}
I64 MemberBuildTest()
{
  CHashClass *types=DeleteAllocRaw(sizeof(CHashClass)*20),*owner,*derived;
  CMemberLst *members=DeleteAllocRaw(sizeof(CMemberLst)*12),*a,*b;
  I64 i,result=0;
  if(!types || !members) return 72;
  for(i=0;i<4;i++) PrsClassInit(types+i*5);
  owner=types+10; derived=types+15; derived->base_class=owner;
  member_diag_errors=0; member_diag_warnings=0;
  members[0].str="m"; members[1].str="z"; members[2].str="a";
  members[3].str="m"; members[4].str="pad"; members[5].str="pad";
  members[6].str="reserved"; members[7].str="reserved";
  members[8].str="_anon_"; members[9].str="_anon_";
  for(i=0;i<12;i++) members[i].member_class=types+1;
  members[2].member_class=types+6;
  for(i=0;i<3;i++) if(!MemberInsert(members+i,owner,TRUE,TRUE,&MemberTestDiagnostic,&member_diag_errors)) result=73;
  if(owner->member_lst_and_root!=members || owner->last_in_member_lst!=members+2 ||
      members[0].left!=members+1 || members[0].right!=members+2 ||
      members[0].next!=members+1 || members[1].next!=members+2 || members[2].next ||
      owner->member_class_base_root!=members || members[0].right_class_base!=members+2 ||
      members[1].left_class_base || members[1].right_class_base ||
      members[0].member_class_base!=types || members[2].member_class_base!=types+5 ||
      member_diag_warnings!=1 || member_diag_errors) result=74;
  if(MemberInsert(members+3,owner,TRUE,TRUE,&MemberTestDiagnostic,&member_diag_errors) ||
      owner->last_in_member_lst!=members+2 || members[2].next || members[3].member_class_base ||
      member_diag_errors!=1 || members[0].use_cnt!=1) result=75;
  //Inherited names are rejected too, leaving the derived owner empty.
  if(MemberInsert(members+3,derived,FALSE,FALSE,&MemberTestDiagnostic,&member_diag_errors) ||
      derived->member_lst_and_root || derived->last_in_member_lst!=&derived->member_lst_and_root ||
      member_diag_errors!=2 || members[0].use_cnt!=2) result=76;
  for(i=4;i<10;i++) {
    members[i].member_class_base=types+5;
    if(!MemberInsert(members+i,owner,FALSE,TRUE,&MemberTestDiagnostic,&member_diag_errors) ||
        members[i].member_class_base) result=77;
  }
  if(member_diag_warnings!=1 || member_diag_errors!=2 || owner->last_in_member_lst!=members+9 ||
      members[2].next!=members+4 || members[9].next || MemberFind("a",owner)!=members+2 ||
      MemberClassBaseFind(types+5,owner)!=members+2) result=78;
  if(!MemberLstCmp(members,members) || !MemberLstCmp(0,0) || MemberLstCmp(members,0)) result=79;
  a=members+10; b=members+11; a->str="arg"; b->str="arg";
  a->flags=MLF_DFT_AVAILABLE; b->flags=MLF_DFT_AVAILABLE;
  a->dft_val=0x100000001; b->dft_val=0x100000001;
  if(!MemberLstCmp(a,b)) result=80;
  b->dft_val=1;
  if(MemberLstCmp(a,b) || !MemberLstCmp(a,b,0)) result=81;
  a->flags=MLF_DFT_AVAILABLE|MLF_STR_DFT_AVAILABLE; b->flags=a->flags;
  a->dft_val=("default"+0)(U64); b->dft_val=("default"+0)(U64);
  if(!MemberLstCmp(a,b)) result=82;
  b->dft_val=("different"+0)(U64);
  if(MemberLstCmp(a,b)) result=83;
  b->flags=0;
  if(MemberLstCmp(a,b)) result=84;
  a->flags=0; a->next=members;
  if(MemberLstCmp(a,b) || MemberLstCmp(a,b,1)) result=85;
  b->next=members+1;
  if(!MemberLstCmp(a,b,1) || MemberLstCmp(a,b)) result=86;
  //The names and type links are borrowed, so release these two bare arrays directly.
  DeleteFreeRaw(members); DeleteFreeRaw(types);
  return result;
}
