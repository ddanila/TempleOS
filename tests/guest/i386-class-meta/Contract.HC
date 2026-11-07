U0 CMLog(U8 *s){while(*s)OutU8(0xE9,*s++);}
U8 *CMFunction(U8 *name)
{
  CHashFun *fun=HashFind(name,Fs->hash_table,HTT_FUN);
  if(fun)return fun->exe_addr;
  return NULL;
}
U8 *CMCapture(CDoc *doc,I64 *size,U8 *name)
{
  U8 *data=DocSave(doc,size),*s=MStrPrint("EXPORT %s %X %X\n",name,data,*size);
  CMLog(s);Free(s);return data;
}
U0 CMCheck()
{
  I64 *r=CAlloc(8),mask=0,n1,n2,n3;U8 *s,*first,*second,*third,*churn;
  CDoc *put=DocPut,*doc=DocNew;Bool raw=Raw(OFF);
  CHashClass *one,*two;CHashGlblVar *v1,*v2;
  CMemberLst *age1,*rank1,*age2,*rank2,*serial;
  I64 (*meta_data)(U8 *name,CMemberLst *member);
  CMemberLstMeta *(*meta_find)(U8 *name,CMemberLst *member);
  CMemberLst *(*member_find)(U8 *name,CHashClass *type);
  U0 (*dump)(U8 *data,U8 *name);
  Fs->put_doc=doc;ExeFile("::/Demo/ClassMeta.HC");Fs->put_doc=put;
  first=CMCapture(doc,&n1,"class-meta-initial.DD");DocDel(doc);
  one=HashFind("Test1Struct",Fs->hash_table,HTT_CLASS);
  two=HashFind("Test2Struct",Fs->hash_table,HTT_CLASS);
  v1=HashFind("t1",Fs->hash_table,HTT_GLBL_VAR);v2=HashFind("t2",Fs->hash_table,HTT_GLBL_VAR);
  meta_data=CMFunction("MemberMetaData");meta_find=CMFunction("MemberMetaFind");
  member_find=CMFunction("MemberFind");dump=CMFunction("DumpStruct");
  if(one && two && v1 && v2 && meta_data && meta_find && member_find && dump) {
    if(one->size==24 && two->size==24 && one->member_cnt==3 && two->member_cnt==3)mask|=1;
    age1=(*member_find)("age",one);rank1=(*member_find)("rank",one);
    age2=(*member_find)("age",two);rank2=(*member_find)("rank",two);
    serial=(*member_find)("serial_num",two);
    if(age1 && rank1 && age2 && rank2 && serial && age1->offset==0 && rank1->offset==16 &&
        age2->offset==0 && rank2->offset==8 && serial->offset==16)mask|=2;
    if(v1->data_addr && v2->data_addr && v1->data_addr(I64 *)[0]==44 &&
        v1->data_addr(I64 *)[2]==3 && v2->data_addr(I64 *)[0]==22 &&
        v2->data_addr(I64 *)[1]==2 && v2->data_addr(I64 *)[2]==55555)mask|=4;
    if((*meta_data)("dft_val",age1)==38 && (*meta_data)("dft_val",rank1)==3 &&
        (*meta_data)("dft_val",rank2)==5 && (*meta_data)("dft_val",serial)==123456)mask|=8;
    F64 percentile;percentile(I64)=(*meta_data)("percentile",age2);
    if((*meta_find)("percentile",age2) && percentile==54.20 &&
        !(*meta_find)("missing",age2) && !(*meta_data)("missing",age2))mask|=16;
    if(!StrCmp((*meta_data)("print_str",age1),"%2d") &&
        !StrCmp((*meta_data)("print_str",serial),"%6d") &&
        (*meta_data)("output_fun",rank1)==CMFunction("RankOut"))mask|=32;
    churn=MAlloc(32768);MemSet(churn,0xA5,32768);Free(churn);
    churn=MAlloc(32768,Fs->code_heap);MemSet(churn,0x5A,32768);Free(churn);
    doc=DocNew;Fs->put_doc=doc;(*dump)(v1->data_addr,"Test1Struct");(*dump)(v2->data_addr,"Test2Struct");Fs->put_doc=put;
    second=CMCapture(doc,&n2,"class-meta-retained.DD");DocDel(doc);
    if(n1==n2 && !MemCmp(first,second,n1))mask|=64;
    v1->data_addr(I64 *)[0]=55;v1->data_addr(I64 *)[2]=2;
    v2->data_addr(I64 *)[0]=40;v2->data_addr(I64 *)[1]=1;v2->data_addr(I64 *)[2]=1234;
    doc=DocNew;Fs->put_doc=doc;(*dump)(v1->data_addr,"Test1Struct");(*dump)(v2->data_addr,"Test2Struct");Fs->put_doc=put;
    third=CMCapture(doc,&n3,"class-meta-mutated.DD");DocDel(doc);
    if(n3>0 && (n1!=n3 || MemCmp(first,third,n1)))mask|=128;
    if((*meta_data)("dft_val",age1)==38 && (*meta_data)("dft_val",rank1)==3 &&
        (*meta_data)("dft_val",serial)==123456 && v1->data_addr(I64 *)[0]==55 &&
        v2->data_addr(I64 *)[2]==1234)mask|=256;
  }
  Raw(raw);*r=mask;s=MStrPrint("EXPORT class-meta-mask.bin %X 8\n",r);CMLog(s);Free(s);
  CMLog("CLASS META DONE\n");Sleep(1000);
}
CMCheck;
