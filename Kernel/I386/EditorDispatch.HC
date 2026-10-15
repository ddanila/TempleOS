//Stable public entry points; optional code/context never belongs to a caller.
CI386EditorContext native_editor_context;
CI386EditorServices native_editor_services;
U8 *native_editor_image;
I64 native_editor_image_bytes;
Bool native_editor_loading;
U0 NativeEditorSetup()
{
 native_editor_context.version=I386_EDITOR_VERSION;native_editor_context.bytes=sizeof(CI386EditorContext);
 native_editor_context.alpha_numeric=char_bmp_alpha_numeric;
 native_editor_context.symbols=console_doc_exports;
 native_editor_context.symbol_count=sizeof(console_doc_exports)/sizeof(CI386KernelSymbol);
 native_editor_context.str_cmp=&StrCmp;native_editor_context.hash_find=&HashFind;
 native_editor_context.alloc=&MAlloc;native_editor_context.free=&Free;
}
U0 NativeEditorRequire()
{
 CI386EditorServices candidate;
 Bool valid=FALSE;
 U32 flags=I386IrqSave;
 if(native_editor_services.version==I386_EDITOR_VERSION){I386IrqRestore(flags);return;}
 if(native_editor_loading||!console_config){I386IrqRestore(flags);throw('Editor',TRUE);}
 native_editor_loading=TRUE;MemSet(&candidate,0,sizeof(candidate));
 try {
  if((*console_config->editor_load)(&candidate,&native_editor_image,&native_editor_image_bytes)&&
     candidate.version==I386_EDITOR_VERSION&&candidate.bytes==sizeof(candidate)&&candidate.init)
   valid=(*candidate.init)(&native_editor_context,sizeof(CI386EditorContext));
  if(valid){MemCpy(&native_editor_services,&candidate,sizeof(candidate));KernelLog("EDITOR loaded ");KernelHex(native_editor_image_bytes);KernelLog("\n");}
 } catch {
  if(native_editor_image)I386HeapFree(console_config->heap,native_editor_image);
  native_editor_image=NULL;native_editor_image_bytes=0;MemSet(&native_editor_services,0,sizeof(native_editor_services));
  native_editor_loading=FALSE;I386IrqRestore(flags);
 }
 if(!valid){
  if(native_editor_image)I386HeapFree(console_config->heap,native_editor_image);
  native_editor_image=NULL;native_editor_image_bytes=0;MemSet(&native_editor_services,0,sizeof(native_editor_services));
 }
 native_editor_loading=FALSE;I386IrqRestore(flags);
 if(!valid)throw('Editor',TRUE);
}
U8 *StrFind(U8*needle,U8*haystack,I64 flags=0){NativeEditorRequire;return (*native_editor_services.str_find)(needle,haystack,flags);}
U0 EdFindNext(CDoc*doc){NativeEditorRequire;(*native_editor_services.find_next)(doc);}
U0 EdSelAll(CDoc*doc,Bool sel){NativeEditorRequire;(*native_editor_services.sel_all)(doc,sel);}
Bool EdFindPaired(CDoc*doc,U8 plus,U8 minus,Bool fwd,Bool abort_on_dbl_colon=FALSE)
{NativeEditorRequire;return (*native_editor_services.find_paired)(doc,plus,minus,fwd,abort_on_dbl_colon);}
Bool EdGoToFun(CDoc*doc,Bool fwd,Bool abort_on_dbl_colon)
{NativeEditorRequire;return (*native_editor_services.go_to_fun)(doc,fwd,abort_on_dbl_colon);}
U0 EdSelFun(CDoc*doc,Bool abort_on_dbl_colon=FALSE){NativeEditorRequire;(*native_editor_services.sel_fun)(doc,abort_on_dbl_colon);}
Bool DocForm(U8*data,U8*name=lastclass,I64 flags=0,U8*header=NULL,U8*footer=NULL)
{NativeEditorRequire;return (*native_editor_services.form)(data,name,flags,header,footer);}
Bool PopUpForm(U8*data,U8*name=lastclass,I64 flags=DOF_SIZE_MIN,U8*header=NULL,U8*footer=NULL)
{NativeEditorRequire;return (*native_editor_services.popup)(data,name,flags,header,footer);}
