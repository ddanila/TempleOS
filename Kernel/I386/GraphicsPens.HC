//Original complete pen tables are root-owned and initialized only when used.
Bool native_graphics_pens_ready;
CI386Task *native_graphics_pen_builder;
class CNativePenScope:CNativeRenderScope {Bool owns;};
U0 NativeGraphicsPensRelease(CNativeRenderScope *base)
{
  CNativePenScope *scope=base;
  I64 i;
  if(!scope->owns)return;
  scope->owns=FALSE;
  if(!native_graphics_pens_ready) {
    for(i=0;i<GR_PEN_BRUSHES_NUM;i++) {
      DCDel(gr.pen_brushes[i]);gr.pen_brushes[i]=NULL;
      DCDel(gr.collision_pen_brushes[i]);gr.collision_pen_brushes[i]=NULL;
      DCDel(gr.even_pen_brushes[i]);gr.even_pen_brushes[i]=NULL;
      DCDel(gr.odd_pen_brushes[i]);gr.odd_pen_brushes[i]=NULL;
    }
    MemSet(gr.circle_lo,0,sizeof(gr.circle_lo));MemSet(gr.circle_hi,0,sizeof(gr.circle_hi));
  }
  native_graphics_pen_builder=NULL;
}
U0 NativeGraphicsPensEnsure()
{
  CNativePenScope scope;
  if(native_graphics_pens_ready)return;
  while(native_graphics_pen_builder) {
    if(native_graphics_pen_builder==I386TaskSelf)throw('PenRecur',TRUE);
    Yield;
    if(native_graphics_pens_ready)return;
  }
  if(!graphics_owner || !TaskValidate(graphics_owner))throw('Graphics',TRUE);
  scope.owns=FALSE;
  try {
    NativeRenderScopeOpen(&scope,&NativeGraphicsPensRelease);
    native_graphics_pen_builder=I386TaskSelf;scope.owns=TRUE;
    GrPenTablesInit;
    native_graphics_pens_ready=TRUE;
    NativeGraphicsPensRelease(&scope);
  } catch {
    NativeGraphicsPensRelease(&scope);NativeRenderScopeClose(&scope);
  }
  NativeRenderScopeClose(&scope);
}
