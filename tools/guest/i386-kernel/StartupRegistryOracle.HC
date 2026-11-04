U0 ExportRegistry(U8 *name,U8 *data,I64 size)
{
 U8 *line=MStrPrint("EXPORT %s %X %X\n",name,data,size);Report(line);Free(line);
}
U0 OriginalStartupRegistry()
{
 CHashGlblVar *symbol=HashFind("sys_registry_doc",adam_task->hash_table,HTT_GLBL_VAR);
 CHashFun *function=HashFind("RegInit",adam_task->hash_table,HTT_FUN);
 CDoc **slot,*saved,*doc;
 U0 (*initialize)();
 U8 *logical,*again;CArcCompress *archive;I64 size;
 if(!symbol || !symbol->data_addr || !function || !function->exe_addr)throw('Registry');
 slot=symbol->data_addr;saved=*slot;
 Del("B:/BootRegistry.HC.Z");
 doc=DocRead("B:/BootRegistry.HC.Z");*slot=doc;
 initialize=function->exe_addr;(*initialize)();
 logical=FileRead("B:/BootRegistry.HC.Z",&size);
 if(!logical || !DocTreeFind(doc,"Adam/SysMsgFlags") || !DocTreeFind(doc,"Adam/SysRegVer"))throw('Registry');
 archive=CompressBuf(logical,size);again=ExpandBuf(archive);
 if(MemCmp(again,logical,size))throw('Registry');
 ExportRegistry("StartupRegistry.HC",logical,size);
 ExportRegistry("StartupRegistry.HC.Z",archive,archive->compressed_size);
 *slot=saved;DocDel(doc);Free(again); //Exported buffers stay live until host capture.
 Report("PASS original startup registry\n");
}
