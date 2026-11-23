I64 ttf_indirect_pointer[2];
I64 ttf_artillery=-1;
Bool ttf_order_logged=FALSE,ttf_blast_logged=FALSE,ttf_resolved_logged=FALSE;

Bool TTFSplashEmpty(I64 row,I64 col)
{
  I64 i,r,c;
  for (i=0;i<7;i++) {
    r=row+row_offsets[i];
    if (row&1)
      c=col+col_offsets_odd[i];
    else
      c=col+col_offsets_even[i];
    if (0<=r<map_rows && 0<=c<map_cols && UnitFind(r,c)) return FALSE;
  }
  return TRUE;
}

U0 TTFAimIndirect(CTask *owner)
{
  I64 i,row,col;
  F64 sx,sy,ex,ey,radius,dd;
  Unit *unit;
  U8 line[256];
  for (i=0;i<UNITS_NUM;i++) {
    unit=&units[0][i];
    if (unit->life>0 && unit->indirect_fire && unit->range>0) {
      radius=unit->range*2*DSIN;
      RowCol2XY(&sx,&sy,unit->row,unit->col);
      for (row=0;row<map_rows;row++)
        for (col=0;col<map_cols;col++) {
          RowCol2XY(&ex,&ey,row,col);
          dd=Sqr(ex-sx)+Sqr(ey-sy);
          if (dd<Sqr(radius/2) && TTFSplashEmpty(row,col)) {
            ttf_artillery=i;
            StrPrint(line,"TTF aim indirect %X %d %d %d %d %d %d %d\n",
                ttf_indirect_pointer,i,ToI64(sx)+x0+owner->pix_left,ToI64(sy)+y0+owner->pix_top,
                ToI64(ex)+x0+owner->pix_left,ToI64(ey)+y0+owner->pix_top,row,col);
            TTFPhaseLog(line);
            return;
          }
        }
    }
  }
  ttf_artillery=-2;
  TTFPhaseLog("FAIL TTF no legal indirect order\n");
}

U0 TTFTrackIndirect(CTask *owner)
{
  IndirectOrders *order;
  U8 line[128];
  ttf_indirect_pointer[0]=ms.pos.x;
  ttf_indirect_pointer[1]=ms.pos.y;
  if (phase==PHASE_INDIRECT0 && turn==1 && ttf_artillery==-1)
    TTFAimIndirect(owner);
  order=indirect_head.next;
  if (!ttf_order_logged && ttf_artillery>=0 && order!=&indirect_head) {
    StrPrint(line,"TTF order queued %d %d %d\n",order->attacker->num,order->row,order->col);
    TTFPhaseLog(line);
    ttf_order_logged=TRUE;
  }
  if (ttf_order_logged && !ttf_blast_logged && indirect_explosion) {
    StrPrint(line,"TTF blast %d %d\n",indirect_row,indirect_col);
    TTFPhaseLog(line);
    ttf_blast_logged=TRUE;
  }
  if (ttf_blast_logged && !ttf_resolved_logged && order==&indirect_head) {
    TTFPhaseLog("TTF queue drained\n");
    ttf_resolved_logged=TRUE;
  }
}
