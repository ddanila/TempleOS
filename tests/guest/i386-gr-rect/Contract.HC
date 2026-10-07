I64 JRContract()
{
  I64 base=Fs->data_heap->used_u8s,mask=0,i,x,y,count,color;
  CDC *dc=DCNew(16,16,Fs);
  DCFill(dc,BLACK);dc->color=RED;
  if(GrRect(dc,2,3,4,5)==20 && dc->body[3*dc->width_internal+2]==RED && dc->body[3*dc->width_internal+1]==BLACK)mask|=1;
  dc->color=BLUE;
  if(GrRect(dc,-2,-3,4,5)==4 && dc->body[0]==BLUE && dc->body[dc->width_internal+1]==BLUE && dc->body[2]==BLACK)mask|=2;
  dc->color=ROP_XOR|GREEN;
  if(GrRect(dc,2,3,4,5)==20 && dc->body[3*dc->width_internal+2]==(RED^GREEN))mask|=4;
  dc->color=ROP_COLLISION;dc->bkcolor=BLACK;dc->collision_cnt=0;
  if(GrRect(dc,0,0,16,16)==24 && dc->collision_cnt==24 && dc->body[0]==BLUE)mask|=8;
  DCExtentsInit(dc);dc->flags|=DCF_RECORD_EXTENTS|DCF_DONT_DRAW;
  if(GrRect(dc,3,4,5,6) && dc->min_x==3 && dc->max_x==7 && dc->min_y==4 && dc->max_y==9 && dc->body[4*dc->width_internal+3]==(RED^GREEN))mask|=16;
  dc->flags=0;DCFill(dc,BLACK);dc->color=RED|BLUE<<16|ROPF_DITHER;
  GrRect(dc,0,0,16,16);count=0;
  for(y=0;y<16;y++)for(x=0;x<16;x++){if((x^y)&1)color=BLUE;else color=RED;if(dc->body[y*dc->width_internal+x]==color)count++;}
  if(count==256)mask|=32;
  DCDel(dc);if(Fs->data_heap->used_u8s==base)mask|=64;
  return mask;
}
