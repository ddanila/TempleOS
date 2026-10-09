#include "/Kernel/I386/BuildRuntime.HH"
public I64 I386BuildModule(U8 *source,U8 *target,Bool boot_module=FALSE)
{//Keep the public entry resident; private building code loads on demand.
  CI386BuildContext context;
  CI386ModuleBinding binding;
  I64 (*build)(CI386BuildContext *context,U8 *source,U8 *target,Bool boot_module);
  U8 *name="I386TaskBuildModule";I64 i=0;
  if(!console_config || !source || !target ||
      !console_config->files->export_at(6,&binding) ||
      binding.kind!=I386_MODULE_EXPORT || !binding.address || !binding.name)return -1;
  while(name[i] && binding.name[i]==name[i])i++;
  if(name[i] || binding.name[i])return -1;
  context.compiler=console_config->compiler;context.files=console_config->files;
  context.includes=console_config->includes;context.types=console_config->types;
  build=binding.address;
  return (*build)(&context,source,target,boot_module);
}
