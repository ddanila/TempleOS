I64 MacroTest()
{
  CCmpCtrl cc; CLexFile parent; CHashTable table; CHash *bucket=0;
  CHashDefineStr first,second; CHashClass scope; CMemberLst member;
  I64 lines=0; U8 input[8];
  input[0]='S'; input[1]='t'; input[2]='a'; input[3]='r'; input[4]='t'; input[5]=59; input[6]=0;
  IdentZero(&table,sizeof(CHashTable)); IdentZero(&first,sizeof(CHashDefineStr)); IdentZero(&second,sizeof(CHashDefineStr));
  IdentZero(&scope,sizeof(CHashClass)); IdentZero(&member,sizeof(CMemberLst));
  table.body=&bucket;
  first.str="Start"; first.type=HTT_DEFINE_STR; first.data="Next";
  second.str="Next"; second.type=HTT_DEFINE_STR; second.data="Final";
  HashAdd(&first,&table); HashAdd(&second,&table);
  IdentSeed(&cc,&parent,input); cc.htc.hash_table_lst=&table;
  if(MacroNext(&cc,&lines)!=TK_IDENT || StrCmp(cc.cur_str,"Final") || cc.cur_str_len!=6 ||
      cc.hash_entry || cc.lex_include_stk!=&parent || cc.cur_buf_ptr!=input+6 || cc.last_U16!=59 ||
      first.use_cnt!=1 || second.use_cnt!=1 || !MacroTextFree(&cc)) return 180;
  cc.flags=CCF_DONT_FREE_BUF|CCF_NO_DEFINES; LexFileSeed(&parent,input); cc.cur_buf_ptr=input;
  if(MacroNext(&cc,&lines)!=TK_IDENT || StrCmp(cc.cur_str,"Start") || cc.hash_entry!=&first ||
      first.use_cnt!=2 || second.use_cnt!=1 || !MacroTextFree(&cc)) return 181;
  first.data=""; cc.flags=CCF_DONT_FREE_BUF; LexFileSeed(&parent,input); cc.cur_buf_ptr=input;
  if(MacroNext(&cc,&lines)!=59 || cc.cur_str || cc.lex_include_stk!=&parent || first.use_cnt!=3) return 182;
  first.data="Next"; member.str="Start"; scope.member_lst_and_root=&member; cc.htc.local_var_lst=&scope;
  cc.flags=CCF_DONT_FREE_BUF; LexFileSeed(&parent,input); cc.cur_buf_ptr=input;
  if(MacroNext(&cc,&lines)!=TK_IDENT || StrCmp(cc.cur_str,"Start") || cc.hash_entry ||
      cc.local_var_entry!=&member || first.use_cnt!=3 || member.use_cnt!=1 || !MacroTextFree(&cc)) return 183;
  return 0;
}
