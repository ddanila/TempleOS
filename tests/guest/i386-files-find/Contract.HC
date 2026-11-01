U8 ff_base[128];
Bool FFSetup(I64 drive)
{
 U8 *old=DirCur,*root=MStrPrint("%C:/",drive),*dir=MStrPrint("%C:/FindProbe",drive);Bool ok;
 ok=Cd(root) && DirMk("FindProbe") && Cd(dir) && DirMk("Sub");
 ok=ok && FileWrite("Alpha.HC","A",1)>0 && FileWrite("Beta.HC","BB",2)>0 && FileWrite("Sub/Child.HC","CCC",3)>0;
 StrCpy(ff_base,dir);ok=Cd(old)&&ok;Free(old);Free(root);Free(dir);return ok;
}
Bool FFName(CDirEntry *e,U8 *name){return e && !StrCmp(e->name,name);}
I64 FFCase(I64 mode)
{
 I64 before=Fs->data_heap->used_u8s,mask=0,flags=0;CDirEntry *tree,*sub;U8 *query;
 if(mode==0)query=MStrPrint("%s/Alpha.HC",ff_base);
 else if(mode==4)query=MStrPrint("%s/Missing.HC",ff_base);
 else query=MStrPrint("%s/*.HC",ff_base);
 if(mode==0 || mode==4)flags=0x200;
 if(mode==1)flags=0x800;
 if(mode==2)flags=1;
 if(mode==3)flags=1|0x200000;
 tree=FilesFind(query,flags);
 if(mode==0){if(FFName(tree,"Alpha.HC") && !tree->next && tree->size==1 && tree->full_name && !StrCmp(tree->full_name,query))mask|=1;}
 else if(mode==1){if(FFName(tree,"Alpha.HC") && FFName(tree->next,"Beta.HC") && !tree->next->next)mask|=1;}
 else if(mode==2){if(FFName(tree,"Sub") && (sub=tree->sub) && FFName(sub,"Child.HC") && sub->parent==tree && !sub->next && FFName(tree->next,"Alpha.HC") && FFName(tree->next->next,"Beta.HC") && !tree->next->next->next)mask|=1;}
 else if(mode==3){if(FFName(tree,"Sub") && !tree->sub && FFName(tree->next,"Child.HC") && !tree->next->sub && FFName(tree->next->next,"Alpha.HC") && FFName(tree->next->next->next,"Beta.HC") && !tree->next->next->next->next)mask|=1;}
 else if(!tree)mask|=1;
 DirTreeDel(tree);Free(query);if(Fs->data_heap->used_u8s==before)mask|=2;return mask;
}
