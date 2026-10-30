I64 sort_calls;
I64 SortAsc(I64 a,I64 b) { sort_calls++;return (a>b)-(a<b); }
I64 SortDesc(I64 a,I64 b) { sort_calls++;return (a<b)-(a>b); }
I64 SortText(I64 a,I64 b) { sort_calls++;return StrCmp(a,b); }
I64 QSortI64Contract()
{
  I64 a[8],b[5],words[4],i,mask=0;
  a[0]=9;a[1]=-3;a[2]=0;a[3]=9;a[4]=7;a[5]=-8;a[6]=7;a[7]=1;
  b[0]=2;b[1]=1;b[2]=3;b[3]=2;b[4]=-1;
  words[0]="pear";words[1]="apple";words[2]="plum";words[3]="apple";
  sort_calls=0;QSortI64(NULL,0,&SortAsc);QSortI64(a,1,&SortAsc);
  if(!sort_calls && a[0]==9)mask|=1;
  QSortI64(a,8,&SortAsc);
  for(i=1;i<8 && a[i-1]<=a[i];i++);
  if(i==8 && a[0]==-8 && a[7]==9)mask|=2;
  if(a[1]==-3 && a[2]==0 && a[3]==1 && a[4]==7 && a[5]==7 && a[6]==9)mask|=4;
  QSortI64(b,5,&SortDesc);
  if(b[0]==3 && b[1]==2 && b[2]==2 && b[3]==1 && b[4]==-1)mask|=8;
  QSortI64(words,4,&SortText);
  if(!StrCmp(words[0],"apple") && !StrCmp(words[1],"apple") &&
      !StrCmp(words[2],"pear") && !StrCmp(words[3],"plum"))mask|=16;
  if(sort_calls>0)mask|=32;
  return mask;
}
