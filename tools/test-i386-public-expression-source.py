#!/usr/bin/env python3
"""Exercise source-loaded full public expression bodies; not normal API delivery."""
from pathlib import Path
import argparse,hashlib,json,runpy,struct,re
root=Path(__file__).resolve().parents[1]
ap=argparse.ArgumentParser(description=__doc__);ap.add_argument('disk',type=Path);ap.add_argument('--out',type=Path,required=True)
ap.add_argument('--classes',action='store_true',help='Also source-load actual class/function-header services; unresolved dependencies remain visible')
ap.add_argument('--statements',action='store_true',help='Also source-load complete shared global/function/statement bodies; implies --classes')
ap.add_argument('--compiler-stream',action='store_true',help='Load complete DirFile/StreamPrint/StreamDir and test shared #exe injection; implies --execute-line')
ap.add_argument('--execute-line',action='store_true',help='Execute actual ExeCmdLine against the shared compiler; implies --statement-code')
ap.add_argument('--statement-code',action='store_true',help='Compile actual top-level statements with LexStmt2Bin; implies --functions')
ap.add_argument('--functions',action='store_true',help='Execute ordinary function bodies through the shared compiler; implies --statements')
args=ap.parse_args()
if args.compiler_stream:args.execute_line=True
if args.execute_line:args.statement_code=True
if args.statement_code:args.functions=True
if args.functions:args.statements=True
if args.statements:args.classes=True
out=args.out.resolve()
if out.exists():ap.error('Use a fresh output directory')
out.mkdir()
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
source=args.disk.resolve()
header=b'''//Diagnostic source-loaded original token lexer. Unresolved compiler services remain explicit externs.
#include "/Kernel/I386/PublicDocument.HH"
#include "/Kernel/I386/PublicHash.HH"
#include "/Kernel/I386/PublicMath.HH"
#include "/Kernel/I386/PublicFiles.HH"
#include "/Kernel/StringLimits.HH"
#include "/Compiler/Keywords.HH"
//Use the original public bitmap header and compare the compatibility alias.
#include "/Kernel/CharBitmaps.HH"
public _extern _CHAR_BMP_PRINTABLE U32 probe_printable[16];
public extern I64 Lex(CCmpCtrl *cc);
public extern U8 *LexExtStr(CCmpCtrl *cc,I64 *_size=NULL,Bool lex_next=TRUE);
public extern I64 LexExpression(CCmpCtrl *cc);
public extern U0 PrsStreamBlk(CCmpCtrl *cc);
#include "/Compiler/LexFiles.HC"
'''
control=(root/'Compiler/PublicControlCore.HC').read_bytes();a=control.index(b'CLexFile *LexFilePush(');b=control.index(b'CLexFile *LexFilePop(',a)
lex=(root/'Compiler/Lex.HC').read_bytes();lex=lex[lex.index(b'U0 LexIncludeStr('):]
lib=(root/'Compiler/LexLib.HC').read_bytes();lib=lib[lib.index(b'U8 *LexExtStr('):]
init=b'''
#include "/Compiler/LexPunctInit.HC"
cmp.dual_U16_tokens1=CAlloc(sizeof(U32)*TK_TKS_NUM);
cmp.dual_U16_tokens2=CAlloc(sizeof(U32)*TK_TKS_NUM);
cmp.dual_U16_tokens3=CAlloc(sizeof(U32)*TK_TKS_NUM);
LexPunctInit(cmp.dual_U16_tokens1,cmp.dual_U16_tokens2,cmp.dual_U16_tokens3);
'''
prefix=header[:header.index(b'#include "/Compiler/LexFiles.HC"')]
cut=lex.index(b'I64 LexSystemToken(')
helpers=re.split(rb'(?=#include "/Compiler/Lex(?:String|Number|Char|Punct|Ident|Define|Conditional)\.HC")',lex[:cut])
lookup=(root/'Compiler/MemberLookup.HC').read_bytes()
lookup=b'#include "/Compiler/MemberLookup.HH"\n'+lookup[lookup.index(b'CMemberLst *MemberClassBaseFind('):]
parts=[prefix,b'#include "/Compiler/LexFiles.HC"\n'+control[a:b]+lookup]+helpers+[lex[cut:],lib,init]
parser_prefix=b'''#include "/Compiler/CompilerA.HH"
#include "/Compiler/ICInfo.HC"
ICInfoInit;
#include "/Compiler/PrsStack.HC"
#include "/Compiler/PrsKeyword.HC"
#include "/Compiler/TargetSize.HC"
public extern CIntermediateCode *OptPass012(CCmpCtrl *cc);
public extern U8 *COCCompile(CCmpCtrl *cc,I64 *_code_size,CDbgInfo **_dbg,I64 *_type);
public extern CHashClass *PrsType(CCmpCtrl *cc,CHashClass **first,I64 *mode,CMemberLst *member,U8 **ident,CHashFun **fun,CHashExport **export_entry,CArrayDim *dim,I64 flags);
'''
code=(root/'Compiler/CodeCtrl.HC').read_bytes();parser_prefix+=code[code.index(b'U0 ICDetach('):code.index(b'U0 COCCopy(')]
code=(root/'Compiler/OptLib.HC').read_bytes();parser_prefix+=code[code.index(b'CIntermediateCode *OptFree('):code.index(b'I64 CmpOffset2Reg(')]
code=(root/'Compiler/CExcept.HC').read_bytes();parser_prefix+=code[code.index(b'U0 ParenWarning('):code.index(b'U0 ICClassPut(')]
parts += [parser_prefix,b'#include "/Compiler/PrsExp.HC"\n']
optimizer=b'''#include "/Compiler/OptCode.HC"
#include "/Compiler/OptTypes.HC"
#include "/Compiler/OptBranch.HC"
#include "/Compiler/OptSize.HC"
'''
code=(root/'Compiler/CExcept.HC').read_bytes();optimizer+=code[code.index(b'U0 ICClassPut('):]
optimizer+=b'#include "/Compiler/OptPass012.HC"\n'
types=b'#include "/Compiler/SymbolInit.HC"\n'
code=(root/'Compiler/PrsLib.HC').read_bytes();types+=code[code.index(b'CHashClass *PrsClassNew('):code.index(b'#include "/Compiler/PublicCodeCore.HC"')]
types+=b'''#include "/Compiler/InternalTypes.HC"
#include "/Compiler/PrsBinary.HC"
U0 ProbePublicCompilerTypes()
{
  I64 i;CHashClass *record;
  cmp.asm_hash=HashTableNew(32);
  for(i=0;i<INTERNAL_TYPES_NUM;i++) {
    record=PrsClassNew;InternalTypeSet(record,i);
    record->str=AStrNew(internal_types_table[i].name);
    HashAdd(record,cmp.asm_hash);cmp.internal_types[record->raw_type]=record;
  }
  cmp.binary_ops=CAlloc(sizeof(U32)*TK_TKS_NUM);PrsBinaryInit(cmp.binary_ops);
}
ProbePublicCompilerTypes;
'''
type_parser=b'public extern CHashClass *PrsClass(CCmpCtrl *cc,I64 keyword,I64 flags,Bool is_extern);\npublic extern CHashFun *PrsFunJoin(CCmpCtrl *cc,CHashClass *type,U8 *name,I64 flags);\n'
code=(root/'Compiler/LexLib.HC').read_bytes()
type_parser+=code[code.index(b'#include "/Compiler/MemberLookup.HC"'):code.index(b'#include "/Kernel/SymbolDelete.HH"')].replace(b'#include "/Compiler/MemberLookup.HC"',b'//Member lookup is already published.')
code=(root/'Compiler/PrsVar.HC').read_bytes()
type_parser+=code[code.index(b'#include "/Compiler/PrsTypeCore.HC"'):code.index(b'#include "/Compiler/PrsDeclarationCore.HC"')]
parts += [optimizer,types,(root/'tests/guest/i386-public-expression/BackendAdapter.HC').read_bytes(),type_parser]
declarations=b'''public extern U0 PrsStaticInit(CCmpCtrl *cc,CMemberLst *member,I64 pass);
'''
code=(root/'Compiler/PrsVar.HC').read_bytes()
declarations+=code[code.index(b'#include "/Compiler/PrsDeclarationCore.HC"'):]
parts.append(declarations)
if args.classes:
 classes=b'#include "/Kernel/SymbolDelete.HC"\n'
 code=(root/'Compiler/LexLib.HC').read_bytes()
 classes+=code[code.index(b'#include "/Kernel/SymbolDelete.HH"'):code.index(b'#include "/Compiler/MemberSizeCore.HC"')]
 code=(root/'Compiler/CMisc.HC').read_bytes();classes+=code[:code.index(b'asm {')]
 code=(root/'Compiler/CExcept.HC').read_bytes();classes+=code[code.index(b'U0 UndefinedExtern('):code.index(b'U0 ParenWarning(')]
 code=(root/'Compiler/PrsStmt.HC').read_bytes();classes+=code[:code.index(b'extern U0 PrsFun(')]
 parts.append(classes)
if args.statements:
  statements=b'''#include "/Compiler/PrsCompileFlags.HH"
 public extern Bool PrsStmt(CCmpCtrl *cc,I64 try_count=0,CCodeMisc *break_label=NULL,I64 flags=CMPF_PRS_SEMICOLON);
 public extern U0 SysSymImportsResolve(U8 *name,I64 flags=0);
 public extern I64 Un(U8 *rip,I64 count=0x80,I64 seg_size=64);
 public extern U0 PrsAsmBlk(CCmpCtrl *cc,I64 flags);
 public extern CAOT *CmpJoin(CCmpCtrl *cc,I64 flags,U8 *map_name=NULL,U8 map_drive=0);
 public extern U0 CmpFixUpJITAsm(CCmpCtrl *cc,CAOT *aot);
 public extern I64 ExeCmdLine(CCmpCtrl *cc);
 '''
  code=(root/'Compiler/PrsStmt.HC').read_bytes()
  statements+=code[code.index(b'extern U0 PrsFun('):]
  parts.append(statements)
if args.functions:
 support=(root/'Kernel/KLoad.HC').read_bytes()
 load_flags=b'\n'.join(line for line in (root/'Kernel/KernelA.HH').read_bytes().splitlines() if line.startswith(b'#define LDF_'))+b'\n'
 parts.append(load_flags+support[:support.index(b'U0 LoadPass1(')])
if args.statement_code:
 main=(root/'Compiler/CMain.HC').read_bytes()
 parts.append(main[:main.index(b'CAOT *CmpJoin(')])
if args.execute_line:
 task=(root/'Kernel/KTask.HC').read_bytes()
 parts.append(b'#include "/Kernel/I386/PublicDate.HH"\n'+task[task.index(b'I64 ExeCmdLine('):task.index(b'#include "/Kernel/SrvTaskContCore.HC"')])
if args.compiler_stream:
 path=(root/'Kernel/BlkDev/DirFileCore.HC').read_bytes()
 misc=(root/'Compiler/CMisc.HC').read_bytes()
 parts.append(path+misc[misc.index(b'U0 StreamPrint('):misc.index(b'CD2I32 *LexD2I32(')])
candidate=b'\n'.join(parts)
(out/'candidate.HC').write_bytes(candidate)
for i,part in enumerate(parts):(out/f'part-{i}.HC').write_bytes(part)
fixture=root/'tests/guest/i386-public-lexer/Contract.HC'
additions={'/Probe/PublicLexer.HC':fixture.read_bytes(),**{f'/Probe/Part{i}.HC':part for i,part in enumerate(parts)}}
for p in fixture.parent.glob('PublicLexer*.HC'):additions['/'+p.name]=p.read_bytes()
graph_fixture=root/'tests/guest/i386-public-expression/ParserGraph.HC'
additions['/Probe/PublicParserGraph.HC']=graph_fixture.read_bytes()
additions['/Probe/PublicExpression.HC']=(root/'tests/guest/i386-public-expression/Contract.HC').read_bytes()
additions['/Probe/PublicTypes.HC']=(root/'tests/guest/i386-public-expression/TypeContract.HC').read_bytes()
additions['/Probe/PublicExpressionRuntime.HC']=(root/'tests/guest/i386-public-expression/Runtime.HC').read_bytes()
additions['/Probe/PublicExpressionLifetime.HC']=(root/'tests/guest/i386-public-expression/Lifetime.HC').read_bytes()
if args.classes:additions['/Probe/PublicClasses.HC']=(root/'tests/guest/i386-public-expression/ClassContract.HC').read_bytes()
if args.functions:additions['/Probe/PublicFunctions.HC']=(root/'tests/guest/i386-public-expression/FunctionsContract.HC').read_bytes()
if args.statement_code:additions['/Probe/PublicStatementCompile.HC']=(root/'tests/guest/i386-public-expression/StatementCompileContract.HC').read_bytes()
if args.execute_line:additions['/Probe/PublicExecuteLine.HC']=(root/'tests/guest/i386-public-expression/ExecuteLineContract.HC').read_bytes()
if args.compiler_stream:additions['/Probe/PublicCompilerStream.HC']=(root/'tests/guest/i386-public-compiler-stream/Contract.HC').read_bytes()
pack=runpy.run_path(str(root/'tools/package-i386-native-image.py'))
r=dict(result='running',scope='Source-loaded complete token lexer, shared expression/type parsers, optimizer and i386 backend on public controls. Nine basic executable cases, eleven runtime call/storage/pointer cases, six type checks, retained-code/unresolved-call/completion checks, token and graph regressions. Complete declaration/initializer bodies are source-loaded; AOT stores and the i386 data-range recorder use normal native bindings; remaining compiler services depend on the requested stages. Class/function-header joins remain unresolved unless --classes is requested; not normal API delivery or full compiler qualification.',disk_sha256=sha(source),candidate_sha256=sha(out/'candidate.HC'),fixture_sha256=sha(fixture))
pin_paths=[Path(__file__).resolve(),source]+[root/('tools/'+n) for n in ('test-i386-autocomplete-interaction.py','test-i386-timeclock-reference.py','test-i386-timeclock-welcome.py','package-i386-native-image.py','build-i386-kernel.py')]
for directory in ('Compiler','Kernel','tests/guest/i386-public-lexer','tests/guest/i386-public-expression','tests/guest/i386-public-compiler-stream'):
 pin_paths += sorted(p for p in (root/directory).rglob('*') if p.is_file() and p.suffix in ('.HC','.HH'))
pins={str(p):sha(p) for p in pin_paths};r['input_sha256']=pins
(out/'runner-source.py').write_bytes(Path(__file__).read_bytes())
r['classes_requested']=args.classes
r['statements_requested']=args.statements
r['functions_requested']=args.functions
r['statement_code_requested']=args.statement_code
r['execute_line_requested']=args.execute_line
r['compiler_stream_requested']=args.compiler_stream
if args.compiler_stream:r['compiler_stream_scope']='Complete original DirFile/StreamPrint/StreamDir bodies with actual shared ExeCmdLine/PrsStreamBlk and lexer reinjection; original differential valid nested/expression/directory cases. Normal delivery and stream error/ownership qualification remain open.'
if args.execute_line:r['execute_line_scope']='Actual complete ExeCmdLine body from KTask.HC, using the actual source-loaded LexStmt2Bin and shared compiler; multi-statement answer/title/mode/unwind contracts. Normal public delivery and stream body ownership remain open.'
if args.statement_code:r['statement_code_scope']='Actual complete LexStmt2Bin, scalar/block/comma/if/F64 top-level statements and retained code, with source-loaded shared parser/backend; normal API delivery, assembly/stream/AOT closure remain open.'
if args.functions:r['function_scope']='Seven ordinary function bodies compiled by shared PrsFun/PrsStmt/optimizer/backend, called after controller release, then code/metadata deletion and exact heap recovery; not normal native public compiler delivery.'
if args.statements:r['statement_scope']='Full global/function/statement bodies are published; ordinary function execution and assembly/stream/AOT services remain unqualified.'
g=None
try:
 before=pack['snapshot'](source.read_bytes())[1]
 for p in pin_paths:
  n='/'+str(p.relative_to(root)) if p.is_relative_to(root) else ''
  if n in before and p.suffix in ('.HC','.HH') and before[n][2]!=p.read_bytes():raise ValueError('Delivered source differs: '+n)
 r['packaging']=pack['package'](source,out/'working.img',additions=additions)
 Guest=runpy.run_path(str(root/'tools/test-i386-autocomplete-interaction.py'))['Guest'];g=Guest(out/'working.img',out/'guest',True);g.delay=.04
 g.wait('DONE native kernel startup\n');r['published_parts']=[]
 for i in range(len(parts)):
  r['attempted_part']=i;g.command(f'#include "C:/Probe/Part{i}.HC"',timeout=240);r['published_parts'].append(i)
  if args.statement_code and i==23:
   g.command('U0 ProbeStatementDefault(){CHashFun *f=HashFind("LexStmt2Bin",Fs->hash_table,HTT_FUN);CMemberLst *m=f->member_lst_and_root;m=m->next->next;if(!(m->flags&MLF_DFT_AVAILABLE) || m->dft_val!=CMPF_PRS_SEMICOLON)throw;}ProbeStatementDefault;')
   r['statement_default_semicolon']='pass'
  if i==0:
   g.command('if ((probe_printable+0)!=(char_bmp_printable+0)) throw;')
   r['printable_alias_identity']='pass'
 g.command('#include "C:/Probe/PublicLexer.HC"');g.command('PLCheck();')
 g.wait('PUBLIC LEXER DONE\n');data=(g.out/'public-lexer.bin').read_bytes();(out/'public-lexer.bin').write_bytes(data)
 r['state']=list(struct.unpack('<24q',data));assert r['state']==[1]*24,r['state']
 g.command('#include \"C:/Probe/PublicParserGraph.HC\"');g.wait('PUBLIC PARSER GRAPH DONE\n')
 data=(g.out/'public-parser-graph.bin').read_bytes();(out/'public-parser-graph.bin').write_bytes(data)
 r['parser_graph_mask']=struct.unpack('<q',data)[0];assert r['parser_graph_mask']==63,r['parser_graph_mask']
 g.command('#include \"C:/Probe/PublicExpression.HC\"');g.wait('PUBLIC EXPRESSION DONE\n')
 data=(g.out/'public-expression.bin').read_bytes();(out/'public-expression.bin').write_bytes(data)
 r['executable_records']=list(struct.unpack('<18q',data));assert r['executable_records']==[1]*9+[42,0x123456789ABCDEF,3,20,1,1,5,4619567317775286272,4615626668101337088],r['executable_records']
 g.command('#include \"C:/Probe/PublicTypes.HC\"');g.wait('PUBLIC TYPES DONE\n')
 data=(g.out/'public-types.bin').read_bytes();(out/'public-types.bin').write_bytes(data)
 r['type_records']=list(struct.unpack('<6q',data));assert r['type_records']==[1]*6,r['type_records']
 g.command('#include \"C:/Probe/PublicExpressionRuntime.HC\"');g.wait('PUBLIC EXPRESSION RUNTIME DONE\n')
 data=(g.out/'public-expression-runtime.bin').read_bytes();(out/'public-expression-runtime.bin').write_bytes(data)
 r['runtime_records']=list(struct.unpack('<24q',data));assert list(struct.unpack('<24q',data))==[1]*11+[7,12,12,12,4615626668101337088,4612811918334230528,4612811918334230528,98,4617878467915022336,1<<40,98,1,1],r['runtime_records']
 g.command('#include \"C:/Probe/PublicExpressionLifetime.HC\"');g.wait('PUBLIC EXPRESSION LIFETIME DONE\n')
 data=(g.out/'public-expression-lifetime-mask.bin').read_bytes();(out/'public-expression-lifetime-mask.bin').write_bytes(data)
 r['lifetime_mask']=struct.unpack('<q',data)[0];assert r['lifetime_mask']==15,r['lifetime_mask']
 if args.classes:
  g.command('#include \"C:/Probe/PublicClasses.HC\"');g.wait('PUBLIC CLASSES DONE\n')
  data=(g.out/'public-classes.bin').read_bytes();(out/'public-classes.bin').write_bytes(data)
  r['class_records']=list(struct.unpack('<8q',data));assert r['class_records']==[1]*8,r['class_records']
 if args.functions:
  g.command('#include "C:/Probe/PublicFunctions.HC"');g.wait('PUBLIC FUNCTIONS DONE\n')
  data=(g.out/'public-functions.bin').read_bytes();(out/'public-functions.bin').write_bytes(data)
  r['function_records']=list(struct.unpack('<16q',data));assert r['function_records']==[1]*7+[26,25,26,20,9,12,4615063718147915776,1,1],r['function_records']
 if args.statement_code:
  g.command('#include "C:/Probe/PublicStatementCompile.HC"');g.wait('PUBLIC STATEMENT COMPILE DONE\n')
  data=(g.out/'public-statement-compile.bin').read_bytes();(out/'public-statement-compile.bin').write_bytes(data)
  r['statement_compile_records']=list(struct.unpack('<22q',data))
  assert r['statement_compile_records']==[1]*10+[42,0x123456789ABCDEF,42,42,42,42,4615626668101337088,4615626668101337088]+[1]*4,r['statement_compile_records']
 if args.execute_line:
  g.command('#include "C:/Probe/PublicExecuteLine.HC"');g.wait('PUBLIC EXECUTE LINE DONE\n')
  data=(g.out/'public-execute-line.bin').read_bytes();(out/'public-execute-line.bin').write_bytes(data)
  r['execute_line_records']=list(struct.unpack('<16q',data));assert r['execute_line_records']==[1]*16,r['execute_line_records']
 if args.compiler_stream:
  g.command('#include "C:/Probe/PublicCompilerStream.HC"');g.wait('PUBLIC COMPILER STREAM DONE\n')
  data=(g.out/'public-compiler-stream.bin').read_bytes();(out/'public-compiler-stream.bin').write_bytes(data)
  r['compiler_stream_records']=list(struct.unpack('<9q',data));assert r['compiler_stream_records']==[1]*9,r['compiler_stream_records']
 g.command('6*7;');r['arithmetic_pixels']=g.result_pixels()
 g.close();g=None
 after=pack['snapshot']((out/'working.img').read_bytes())[1]
 if {n for n in set(before)|set(after) if before.get(n)!=after.get(n)}!=set(additions):raise ValueError('Unexpected filesystem changes')
 r['filesystem']=runpy.run_path(str(root/'tools/build-i386-kernel.py'))['verify_mutated_volume'](out/'working.img')
 r['result']='pass'
except BaseException as e:
 r.update(result='fail',error=str(e));raise
finally:
 if g:
  try:g.close()
  except Exception as e:r.update(result='fail',cleanup_error=str(e))
 r['source_unchanged']=sha(source)==r['disk_sha256']
 r['inputs_unchanged']=all(p.is_file() and sha(p)==pins[str(p)] for p in pin_paths)
 if not r['inputs_unchanged']:r.update(result='fail',error='Inputs changed')
 (out/'result.json').write_text(json.dumps(r,indent=2)+'\n')
if r['result']!='pass':raise RuntimeError(r.get('error',r.get('cleanup_error','Source-loaded expression checks failed')))
