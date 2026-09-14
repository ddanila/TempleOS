U0 IdentZero(U8 *bytes,I64 size) { I64 i; for(i=0;i<size;i++) bytes[i]=0; }
I64 IdentLookupTest()
{
  CCmpCtrl cc; CLexFile file; CHashTable child,parent; CHash *child_bucket=0,*parent_bucket=0;
  CHash global,define; CHashClass local,base; CMemberLst member;
  U8 input[2]; CHash *found;
  input[0]=0; IdentSeed(&cc,&file,input);
  IdentZero(&child,sizeof(CHashTable)); IdentZero(&parent,sizeof(CHashTable));
  IdentZero(&global,sizeof(CHash)); IdentZero(&define,sizeof(CHash));
  IdentZero(&local,sizeof(CHashClass)); IdentZero(&base,sizeof(CHashClass)); IdentZero(&member,sizeof(CMemberLst));
  child.body=&child_bucket; child.next=&parent; parent.body=&parent_bucket;
  global.str="name"; global.type=HTT_GLBL_VAR; global.use_cnt=0xFFFFFFFF;
  define.str="name"; define.type=HTT_DEFINE_STR;
  HashAdd(&global,&child); HashAdd(&define,&parent);
  cc.htc.hash_table_lst=&child; cc.htc.hash_mask=HTT_GLBL_VAR|HTT_DEFINE_STR;
  if(LexIdentFind(&cc,"name")!=&global || global.use_cnt!=0 || cc.local_var_entry) return 110;
  cc.htc.hash_mask=HTT_DEFINE_STR;
  if(LexIdentFind(&cc,"name")!=&define || define.use_cnt!=1) return 111;
  member.str="name"; member.use_cnt=0xFFFFFFFF;
  base.member_lst_and_root=&member; local.base_class=&base; cc.htc.local_var_lst=&local;
  if(LexIdentFind(&cc,"name") || cc.local_var_entry!=&member || member.use_cnt!=0 ||
      define.use_cnt!=1 || global.use_cnt!=0) return 112;
  if(LexIdentFind(&cc,"missing") || cc.local_var_entry) return 113;
  cc.htc.local_var_lst=0; cc.flags|=CCF_NO_DEFINES;
  if(LexIdentFind(&cc,"name")!=&define || define.use_cnt!=2) return 114;
  cc.htc.hash_mask=HTT_FUN;
  if(LexIdentFind(&cc,"name") || cc.local_var_entry) return 115;
  cc.htc.hash_table_lst=0; cc.local_var_entry=&member;
  if(LexIdentFind(&cc,"name") || cc.local_var_entry) return 116;
  return 0;
}
