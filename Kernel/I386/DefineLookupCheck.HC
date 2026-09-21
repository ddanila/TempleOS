//Same list/definition lookup corpus on original x64 and retained native code.
I64 DefineLookupCheck()
{
  U8 *list="zero\0@nil\0one\0only\0",*name="LookupProbe";
  CHashTable *saved=Fs->hash_table,*parent=HashTableNew(1),*child=HashTableNew(1);
  CHashDefineStr *entry,*shadow;
  I64 result=16;
  parent->next=saved; child->next=parent;
  try {
    Fs->hash_table=parent;
    entry=DefineLstLoad(name,list);
    Fs->hash_table=child;
    if(LstSub(-1,list) || LstSub(3,list) || LstSub(0,0) || LstSub(0,"")) result=-1;
    if(StrCmp(LstSub(0,list),"zero") || StrCmp(LstSub(1,list),"one") || StrCmp(LstSub(2,list),"only")) result=-2;
    if(LstMatch("nil",list)!=0 || LstMatch("ni",list)!=0 || LstMatch("one",list)!=1) result=-3;
    if(LstMatch("on",list)!=-2 || LstMatch("",list)!=-2 || LstMatch("on",list,LMF_EXACT)!=-1) result=-4;
    if(LstMatch("NIL",list)!=-1 || LstMatch("NIL",list,LMF_IGNORE_CASE)!=0) result=-5;
    if(LstMatch("nil",0)!=-1 || LstMatch("nil","")!=-1 || LstMatch("missing",list)!=-1) result=-6;
    if(LstMatch("ON",list,LMF_IGNORE_CASE|LMF_EXACT)!=-1 || LstMatch("ONE",list,LMF_IGNORE_CASE|LMF_EXACT)!=1) result=-7;
    if(Define(name)!=entry->data || DefineCnt(name)!=3 || DefineSub(1,name)!=entry->sub_idx[1]) result=-8;
    if(DefineSub(-1,name) || DefineSub(3,name) || Define(0) || DefineSub(0,0) || DefineCnt(0)!=-1) result=-9;
    if(DefineMatch("on",name)!=-2 || DefineMatch("NIL",name,LMF_IGNORE_CASE)!=0 || DefineMatch("one",name,LMF_EXACT)!=1) result=-10;
    shadow=DefineLstLoad(name,"local\0");
    if(Define(name)!=shadow->data || DefineCnt(name)!=1 || DefineSub(0,name)!=shadow->data) result=-11;
    if(DefineMatch("nil",name)!=-1 || DefineMatch("local",name)!=0 || DefineSub(1,name)) result=-12;
    if(DefineCnt("ST_COLORS")!=16 || StrCmp(DefineSub(15,"ST_COLORS"),"WHITE")) result=-13;
    shadow->cnt=-1;
    if(DefineCnt(name)!=-1 || DefineSub(0,name) || Define(name)!=shadow->data) result=-14;
    shadow->cnt=1;
    Fs->hash_table=parent;
    if(Define(name)!=entry->data || DefineCnt(name)!=3 || DefineMatch("only",name)!=2) result=-15;
    if(DefineMatch("unused",0)!=-1 || LstMatch("nil",list,LMF_EXACT)!=0) result=-16;
  } catch {
    Fs->hash_table=saved; child->next=parent->next=0;
    HashTableDel(child); HashTableDel(parent);
  }
  Fs->hash_table=saved; child->next=parent->next=0;
  HashTableDel(child); HashTableDel(parent); return result;
}
I64 DefineMissingCheck(I64 kind,Bool check_heap=FALSE)
{
  I64 before=Fs->data_heap->used_u8s,code=0;
  try {
    switch(kind) {
      case 0: Define("Missing%sLookup"); break;
      case 1: DefineSub(0,"Missing%sLookup"); break;
      case 2: DefineCnt("Missing%sLookup"); break;
      case 3: DefineMatch("x","Missing%sLookup"); break;
    }
  } catch { code=Fs->except_ch; Fs->catch_except=TRUE; }
  return code=='UndefDef' && (!check_heap || Fs->data_heap->used_u8s==before);
}
