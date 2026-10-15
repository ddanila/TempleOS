#include "/Kernel/SymbolTypes.HH"
//A child-local export must never replace the permanent Console callback table.
public class ELOpaque { I64 value; };
class ELExport:CHashExport { U32 kind; };
CTask *el_child;I64 el_result,el_poison;
CHash *el_parent_export;
CDoc *ELPoison(U8*name,CTask*task){el_poison++;return NULL;}
Bool ELUse()
{
 I64 before=Fs->data_heap->used_u8s;ELOpaque data;Bool result;
 CDoc*put=DocPut,*display=DocDisplay,*border=DocBorder;U8*end=Fs->task_end_cb;
 if(!HashFind("ELOpaque",Fs->hash_table,HTT_CLASS))return FALSE;
 data.value=42;result=DocForm(&data,"ELOpaque");
 return !result&&data.value==42&&DocPut==put&&DocDisplay==display&&DocBorder==border&&
   Fs->task_end_cb==end&&Fs->data_heap->used_u8s==before;
}
U0 ELRun(U8*unused)
{
 ELExport*shadow=CAlloc(sizeof(ELExport));
 shadow->str=StrNew("_DOC_NEW");shadow->type=HTT_EXPORT_SYS_SYM;
 shadow->kind=1;shadow->val=&ELPoison;HashAdd(shadow,Fs->hash_table);
 el_result=HashFind("_DOC_NEW",Fs->hash_table,HTT_EXPORT_SYS_SYM)==shadow&&ELUse&&!el_poison;
 HashRemDel(shadow,Fs->hash_table);
}
Bool ELWait()
{
 I64 end=cnts.jiffies+20000;
 while(TaskValidate(el_child)&&cnts.jiffies<end)Yield;
 return !TaskValidate(el_child)&&el_result==1&&!el_poison;
}
Bool ELStart()
{
 el_result=-1;el_child=Spawn(&ELRun,NULL,"Editor owner",-1,Fs);
 return el_child&&ELWait;
}
Bool ELRepeat()
{
 I64 n=Fs->data_heap->bp->used_u8s,r=Fs->data_heap->bp->alloced_u8s;
 return ELStart&&Fs->data_heap->bp->used_u8s==n&&Fs->data_heap->bp->alloced_u8s==r;
}

U0 ELSetup(){el_parent_export=HashFind("_DOC_NEW",Fs->hash_table,HTT_EXPORT_SYS_SYM);}
