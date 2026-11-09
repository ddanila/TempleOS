#ifndef I386_DC_NEW_SCOPE_INCLUDED
#define I386_DC_NEW_SCOPE_INCLUDED
#include "/Kernel/I386/RenderScope.HH"
class CNativeDCNewScope:CNativeRenderScope {CDC **context;};
extern U0 NativeDCNewScopeOpen(CNativeDCNewScope *scope,CDC **context);
extern U0 NativeRenderScopeClose(CNativeRenderScope *scope);
#define DC_NEW_SCOPE_LOCAL CNativeDCNewScope native_dc_new_scope
#define DC_NEW_SCOPE_OPEN NativeDCNewScopeOpen(&native_dc_new_scope,&res)
#define DC_NEW_SCOPE_COMMIT native_dc_new_scope.context=NULL
#define DC_NEW_SCOPE_CLOSE NativeRenderScopeClose(&native_dc_new_scope)
#endif
