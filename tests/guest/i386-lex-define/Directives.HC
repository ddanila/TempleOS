U0 DirectiveSeed(CCmpCtrl *cc,CLexFile *file,CHashTable *table,CHashGeneric *keyword,CHash **bucket,U8 *source)
{
  IdentZero(table,sizeof(CHashTable)); IdentZero(keyword,sizeof(CHashGeneric));
  *bucket=0; table->body=bucket;
  keyword->str="define"; keyword->type=HTT_KEYWORD; keyword->user_data0=KW_DEFINE;
  HashAdd(keyword,table); IdentSeed(cc,file,source); file->full_name="Source.HC";
  cc->htc.hash_table_lst=cc->htc.define_hash_table=table;
}
Bool DirectiveClear(CCmpCtrl *cc,CHashTable *table,CHash *keyword)
{
  CHash *entry;
  cc->hash_entry=0; cc->local_var_entry=0;
  if(!MacroTextFree(cc)) return FALSE;
  while(table->body[0]!=keyword) {
    entry=table->body[0]; if(!entry) return FALSE;
    table->body[0]=entry->next;
    if(!DirectiveFree(entry)) return FALSE;
  }
  return TRUE;
}
I64 DirectiveTest()
{
  CCmpCtrl cc; CLexFile file; CHashTable table; CHashGeneric keyword;
  CHash *bucket=0; CHashDefineStr *entry,*older; CHashClass local; CMemberLst member; I64 lines=0;
  DirectiveSeed(&cc,&file,&table,&keyword,&bucket,"#define M 2e0\nM;");
  cc.opts|=1<<OPTf_KEEP_PRIVATE; cc.cur_help_idx="Help/Thing";
  if(MacroNext(&cc,&lines)!=TK_F64 || cc.cur_f64(U64)!=0x4000000000000000) return 500;
  entry=HashFind("M",&table,HTT_DEFINE_STR);
  if(!entry || StrCmp(entry->str,"M") || StrCmp(entry->data,"2e0") || entry->cnt!=-1 ||
      StrCmp(entry->src_link,"FL:Source.HC,1") || StrCmp(entry->idx,"Help/Thing") ||
      entry->idx==cc.cur_help_idx || !(entry->type&HTF_PRIVATE) || cc.cur_str ||
      cc.flags&CCF_NO_DEFINES) return 501;
  if(MacroNext(&cc,&lines)!=59 || MacroNext(&cc,&lines)!=TK_EOF || !DirectiveClear(&cc,&table,&keyword)) return 502;
  DirectiveSeed(&cc,&file,&table,&keyword,&bucket,"#define M 2e0\n#define M 3e0\nM;");
  if(MacroNext(&cc,&lines)!=TK_F64 || cc.cur_f64(U64)!=0x4008000000000000) return 503;
  entry=HashFind("M",&table,HTT_DEFINE_STR); older=HashFind("M",&table,HTT_DEFINE_STR,2);
  if(!entry || !older || entry==older || StrCmp(entry->data,"3e0") || StrCmp(older->data,"2e0") ||
      StrCmp(entry->src_link,"FL:Source.HC,2") || !DirectiveClear(&cc,&table,&keyword)) return 504;
  DirectiveSeed(&cc,&file,&table,&keyword,&bucket,"#define Empty\nEmpty ;");
  if(MacroNext(&cc,&lines)!=59) return 505;
  entry=HashFind("Empty",&table,HTT_DEFINE_STR);
  if(!entry || *entry->data || StrCmp(entry->src_link,"FL:Source.HC,2") || !DirectiveClear(&cc,&table,&keyword)) return 506;
  DirectiveSeed(&cc,&file,&table,&keyword,&bucket,"#define End");
  if(MacroNext(&cc,&lines)!=TK_EOF) return 507;
  entry=HashFind("End",&table,HTT_DEFINE_STR);
  if(!entry || *entry->data || !DirectiveClear(&cc,&table,&keyword)) return 508;
  DirectiveSeed(&cc,&file,&table,&keyword,&bucket,"#define M 2e0\nM;"); file.line_num=0x100000001;
  if(MacroNext(&cc,&lines)!=TK_F64) return 509;
  entry=HashFind("M",&table,HTT_DEFINE_STR);
  if(!entry || StrCmp(entry->src_link,"FL:Source.HC,4294967297") || !DirectiveClear(&cc,&table,&keyword)) return 510;
  DirectiveSeed(&cc,&file,&table,&keyword,&bucket,"#define M 2e0\nM;"); file.line_num=-5;
  if(MacroNext(&cc,&lines)!=TK_F64) return 511;
  entry=HashFind("M",&table,HTT_DEFINE_STR);
  if(!entry || StrCmp(entry->src_link,"FL:Source.HC,1") || !DirectiveClear(&cc,&table,&keyword)) return 512;
  DirectiveSeed(&cc,&file,&table,&keyword,&bucket,"#define 123\n;");
  if(MacroNext(&cc,&lines)!=59 || bucket!=&keyword || cc.flags&CCF_NO_DEFINES || !DirectiveClear(&cc,&table,&keyword)) return 513;
  DirectiveSeed(&cc,&file,&table,&keyword,&bucket,"#define M 2e0\nM;");
  IdentZero(&local,sizeof(CHashClass)); IdentZero(&member,sizeof(CMemberLst));
  member.str="M"; local.member_lst_and_root=&member; cc.htc.local_var_lst=&local;
  if(MacroNext(&cc,&lines)!=TK_IDENT || cc.local_var_entry!=&member || StrCmp(cc.cur_str,"M")) return 514;
  entry=HashFind("M",&table,HTT_DEFINE_STR);
  if(!entry || StrCmp(entry->data,"2e0") || !DirectiveClear(&cc,&table,&keyword)) return 515;
  return 0;
}
