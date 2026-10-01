//Link a selected kernel and five boot helper modules from mounted RedSea files.
//The flat image is a file; publishing it into the reserved boot area is separate.
#include "/Kernel/I386/ModuleLoad.HC"
U8 *boot_image_names[5]={"SysTry.t32m","TaskContext.t32m",
  "ExceptContext.t32m","IrqEntry.t32m","ExceptionEntry.t32m"};
public I64 I386BuildBootImage(U8 *kernel_path,U8 *module_dir,U8 *target_path)
{
  U8 path[256],*modules[6],*image=0;
  I64 sizes[6],i,j,prefix,required=8,result=-1;
  CI386ModuleHeader *header;
  CI386Heap *heap;
  CI386TaskSymbols *scope;
  Bool clean=TRUE;
  if(!console_config || !I386TaskSelf ||
      !(scope=I386TaskSelf->symbol_state) || scope->task!=I386TaskSelf ||
      !(heap=scope->heap) ||
      !kernel_path || !module_dir || !target_path ||
      !(prefix=StrLen(module_dir)) || prefix>220 || module_dir[prefix-1]!='/')
    return -1;
  for(i=0;i<6;i++) { modules[i]=0; sizes[i]=0; }
  modules[0]=(*console_config->files->read)(heap,kernel_path,sizes,0,0);
  if(!modules[0]) goto boot_image_done;
  for(i=1;i<6;i++) {
    for(j=0;j<prefix;j++) path[j]=module_dir[j];
    for(j=0;boot_image_names[i-1][j];j++) path[prefix+j]=boot_image_names[i-1][j];
    path[prefix+j]=0;
    modules[i]=(*console_config->files->read)(heap,path,sizes+i,0,0);
    if(!modules[i]) goto boot_image_done;
  }
  //Reject an oversized image before the expensive symbol-resolution pass.
  for(i=0;i<6;i++) {
    if(sizes[i]<32) goto boot_image_done;
    header=modules[i];
    if(header->code_size>960*512-4096-required) goto boot_image_done;
    required+=header->code_size;
  }
  required=I386LoadBoundAt(modules,sizes,6,0,0,"Main",0,0,0x11000);
  if(required<8 || required>960*512-4096 ||
      !(image=I386HeapAlloc(heap,required))) goto boot_image_done;
  if(I386LoadBoundAt(modules,sizes,6,image,required,"Main",0,0,0x11000)!=required)
    goto boot_image_done;
  if((*console_config->files->write)(target_path,image,required,0)) result=required;
boot_image_done:
  if(image && !I386HeapFree(heap,image)) clean=FALSE;
  for(i=0;i<6;i++) if(modules[i] && !I386HeapFree(heap,modules[i])) clean=FALSE;
  if(!clean) return -1;
  return result;
}
