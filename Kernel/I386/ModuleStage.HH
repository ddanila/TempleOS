#ifndef I386_MODULE_STAGE_INCLUDED
#define I386_MODULE_STAGE_INCLUDED
#define I386_STAGE_OPEN 1
#define I386_STAGE_FAILED 2
#define I386_STAGE_SEALED 3
#define I386_STAGE_READY 4
#define I386_STAGE_READ 5
#define I386_STAGE_RELEASED 6
class CI386ModuleStage {
  U8 *context;
  I64 bytes,written;
  U32 phase;
  Bool owned;
  I64 (*write)(U8 *context,U32 offset,U8 *buffer,U32 bytes);
  Bool (*flush)(U8 *context);
  I64 (*read)(U8 *context,U8 *buffer,I64 bytes);
  Bool (*release)(U8 *context);
};
#endif
