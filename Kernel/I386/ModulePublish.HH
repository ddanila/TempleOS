#ifndef I386_MODULE_PUBLISH_INCLUDED
#define I386_MODULE_PUBLISH_INCLUDED
#define I386_PUBLISH_PREPARED 1
#define I386_PUBLISH_UNCERTAIN 2
#define I386_PUBLISH_COMMITTED 3
#define I386_PUBLISH_DONE 4
#define I386_PUBLISH_OLD 1
#define I386_PUBLISH_NEW 2
class CI386ModulePublish {
  U8 *context;
  I64 *owned_block;
  U32 phase;
  Bool (*flush)(U8 *context);
  Bool (*write)(U8 *context);
  U32 (*observe)(U8 *context);
  Bool (*reclaim)(U8 *context);
};
#endif
