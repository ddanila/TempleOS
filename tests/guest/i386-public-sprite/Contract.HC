I64 PublicSpriteContract()
{
  CDC *dc=DCNew(32,32);U8 data[32];I64 mask=0;
  I64 flags=dc->flags,color=RED,thick=dc->thick;
  dc->color=color;MemSet(data,0,sizeof(data));
  Sprite3(dc,0,0,0,data);
  if(dc->body[4*dc->width_internal+3]==BLACK)mask|=1;
  data[0]=8;(data+1)(I32 *)[0]=3;(data+5)(I32 *)[0]=4;
  Sprite3(dc,0,0,0,data);
  if(dc->body[4*dc->width_internal+3]==RED && dc->body[4*dc->width_internal+4]==BLACK)mask|=2;
  MemSet(data,0,sizeof(data));data[0]=7;(data+1)(I32 *)[0]=5;(data+5)(I32 *)[0]=6;
  data[9]=8;(data+10)(I32 *)[0]=1;(data+14)(I32 *)[0]=2;
  Sprite3(dc,2,3,0,data);
  if(dc->body[11*dc->width_internal+8]==RED)mask|=4;
  MemSet(data,0,sizeof(data));data[0]=1;data[1]=GREEN;data[2]=8;
  (data+3)(I32 *)[0]=12;(data+7)(I32 *)[0]=13;
  Sprite3(dc,0,0,0,data);
  if(dc->body[13*dc->width_internal+12]==GREEN && dc->color==color)mask|=8;
  (data+3)(I32 *)[0]=14;(data+7)(I32 *)[0]=15;
  Sprite3(dc,0,0,0,data,TRUE);
  if(dc->body[15*dc->width_internal+14]==BLACK && dc->color==color)mask|=16;
  if(dc->flags==flags && dc->thick==thick)mask|=32;
  DCClear(dc);dc->color=RED;
  if(GrLine(dc,1,2,5,2) && dc->body[2*dc->width_internal+1]==RED &&
    dc->body[2*dc->width_internal+5]==RED && dc->body[3*dc->width_internal+3]==BLACK)mask|=64;
  DCDel(dc);return mask;
}
