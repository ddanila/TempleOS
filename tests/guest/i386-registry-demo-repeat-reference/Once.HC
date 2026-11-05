#include "T:/FirstRegistryDemo.HC"
//Reload the document written by the first unchanged launch, without defaults.
CDoc *repeat_registry=DocRead("B:/BootRegistry.HC.Z");
*demo_pointer=repeat_registry;
CDoc *repeat_output=DocNew,*repeat_saved_put=Fs->put_doc;
Fs->put_doc=repeat_output;
F64 repeat_before=tS;
#include "::/Demo/RegistryDemo.HC"
F64 repeat_after=tS;
I64 *repeat_record=CAlloc(32);
repeat_record[0]=RegExe("DemoCompany/Game1/SimpleVal");
repeat_record[1]=best_score(U64);
repeat_record[2]=repeat_before(U64);repeat_record[3]=repeat_after(U64);
I64 repeat_size,repeat_output_size;
U8 *repeat_state=FileRead("B:/BootRegistry.HC.Z",&repeat_size);
U8 *repeat_text=DocSave(repeat_output,&repeat_output_size);
ExportRegistry("repeat-record.bin",repeat_record,32);
ExportRegistry("repeat-registry.HC",repeat_state,repeat_size);
ExportRegistry("repeat-output.DD",repeat_text,repeat_output_size);
Fs->put_doc=repeat_saved_put;*demo_pointer=demo_saved;
Report("DONE original registry demo repeat\n");
