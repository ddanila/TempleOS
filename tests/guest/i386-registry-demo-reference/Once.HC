U0 Report(U8 *s){while(*s)OutU8(0xE9,*s++);}
#include "T:/StartupRegistryOracle.HC"
OriginalStartupRegistry;
CHashGlblVar *demo_slot=HashFind("sys_registry_doc",adam_task->hash_table,HTT_GLBL_VAR);
CDoc **demo_pointer=demo_slot->data_addr;
CDoc *demo_saved=*demo_pointer;
*demo_pointer=DocRead("B:/BootRegistry.HC.Z");
F64 demo_before=tS;
#include "::/Demo/RegistryDemo.HC"
F64 demo_after=tS;
I64 *demo_record=CAlloc(32);
demo_record[0]=RegExe("DemoCompany/Game1/SimpleVal");
demo_record[1]=best_score(U64);demo_record[2]=demo_before(U64);demo_record[3]=demo_after(U64);
I64 demo_size;
U8 *demo_state=FileRead("B:/BootRegistry.HC.Z",&demo_size);
I64 demo_output_size;
U8 *demo_text=DocSave(Fs->put_doc,&demo_output_size);
ExportRegistry("demo-record.bin",demo_record,32);
ExportRegistry("demo-registry.HC",demo_state,demo_size);
ExportRegistry("demo-output.DD",demo_text,demo_output_size);
*demo_pointer=demo_saved;
Report("DONE original registry demo\n");
