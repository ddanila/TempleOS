Bool DNCheck(U8 *input,U8 *expected)
{
 I64 before=Fs->data_heap->used_u8s;U8 *result=DirNameAbs(input);
 Bool ok=result && !StrCmp(result,expected);Free(result);
 return ok && Fs->data_heap->used_u8s==before;
}
I64 DNContract(I64 drive)
{
 I64 mask=0;U8 *old=DirCur,*root=MStrPrint("%C:/",drive),*base=MStrPrint("%C:/DirProbe",drive),*leaf=MStrPrint("%C:/DirProbe/Leaf",drive),*other=MStrPrint("%C:/Other",drive),*explicit=MStrPrint("%C:/A/../B",drive),*explicit_want=MStrPrint("%C:/B",drive);
 if(Cd(root) && DirMk("DirProbe") && Cd(base))mask|=1;
 if(DNCheck(NULL,base))mask|=2;
 if(DNCheck("",base))mask|=4;
 if(DNCheck("Sub/../Leaf",leaf))mask|=8;
 if(DNCheck("/Other",other))mask|=16;
 if(DNCheck(explicit,explicit_want))mask|=32;
 if(DNCheck("../",root))mask|=64;
 if(Cd(old))mask|=128;
 Free(old);Free(root);Free(base);Free(leaf);Free(other);Free(explicit);Free(explicit_want);
 return mask;
}
