#define KEY_CASES 10
#define KEY_TABLE_BYTES (KEY_CASES*256*(1+8+64))
U8 *key_table;
I64 key_flags[KEY_CASES]={0,SCF_SHIFT,SCF_CTRL,SCF_CAPS,SCF_SHIFT|SCF_CAPS,
  SCF_CTRL|SCF_SHIFT,SCF_ALT,SCF_E0_PREFIX,SCF_NO_SHIFT,SCF_KEY_UP};
I64 BuildKeyTable()
{
  I64 i,j,index,n;U8 *st,*names;I64 *inverse;
  key_table=CAlloc(KEY_TABLE_BYTES);if(!key_table)return 0;
  inverse=(key_table+KEY_CASES*256)(I64 *);
  names=key_table+KEY_CASES*256*(1+8);
  for(i=0;i<KEY_CASES;i++)for(j=0;j<256;j++) {
    index=i*256+j;
    key_table[index]=ScanCode2Char(key_flags[i]|j);
    inverse[index]=Char2ScanCode(j,key_flags[i]);
    st=ScanCode2KeyName(key_flags[i]|j);
    if(!st)return 0;
    for(n=0;n<63 && st[n];n++)names[index*64+n]=st[n];
    Free(st);
  }
  return 1;
}
