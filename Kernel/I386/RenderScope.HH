#ifndef I386_RENDER_SCOPE_TYPES_INCLUDED
#define I386_RENDER_SCOPE_TYPES_INCLUDED
class CNativeRenderScope {
  CNativeRenderScope *next;
  CI386Task *task;
  U0 (*previous_cleanup)(CI386Task *task);
  U0 (*release)(CNativeRenderScope *scope);
  U0 (*prepare_exit)(CNativeRenderScope *scope);
  CI386Task *resource_owner,*window_owner;
  U8 *resource;
  Bool retiring_resource,legacy_view;
};
#endif
