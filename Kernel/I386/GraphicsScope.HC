class CNativeGraphicsScope:CNativeRenderScope {
  CDC **alias;
  Bool *lease;
};
U0 NativeGraphicsScopeRelease(CNativeRenderScope *base)
{
  CNativeGraphicsScope *scope=base;
  CDC *alias=NULL;
  if(scope->alias) {alias=*scope->alias;*scope->alias=NULL;}
  DCDel(alias);
  if(scope->lease)*scope->lease=FALSE;
}
U0 NativeGraphicsScopeOpen(CNativeGraphicsScope *scope,CDC **alias,Bool *lease)
{
  scope->alias=alias;scope->lease=lease;
  NativeRenderScopeOpen(scope,&NativeGraphicsScopeRelease);
}
#define GRAPHICS_FRAME_SCOPE_LOCAL CNativeGraphicsScope native_graphics_scope
#define GRAPHICS_FRAME_SCOPE_OPEN NativeGraphicsScopeOpen(&native_graphics_scope,&alias,NULL)
#define GRAPHICS_FRAME_SCOPE_CLOSE NativeRenderScopeClose(&native_graphics_scope)
