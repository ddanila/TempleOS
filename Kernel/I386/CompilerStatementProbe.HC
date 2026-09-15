//Compile complete source declarations through the retained shared statement core.
#include "/Compiler/PrsCompileFlags.HH"
U0 ProbeStatements(CI386CompilerProbe *probe,CI386Heap *heap,CCmpCtrl *outer)
{
  CI386Task *task=I386TaskSelf;
  CCmpCtrl *cc;
  CPrsSymbolServices *symbols;
  CPrsExpressionServices *expression;
  CHashFun *main_fun;
  CIntermediateCode *node;
  U8 *source,*deep;
  I64 kind,expected,actual,accepted,i,length,source_flags,count;
  I64 used=heap->used,allocations=heap->allocations,refs=task->lifetime_refs;
  U32 flags=GetRFlags;
  I64 (*entry)();
  for(kind=0;kind<34;kind++) {
    source="I64i Main(){I64i i,sum=0;for(i=0;i<7;i++)sum+=i;return sum*2;}"; expected=42;
    switch(kind) {
      case 1: source="I64i Main(){I64i n=5,r=1;while(n)r*=n--;do{r++;}while(r<123);return r;}"; expected=123; break;
      case 2: source="I64i Main(){I64i x=3,r;switch(x){case 1...3:r=40;break;default:r=0;}goto done;r=0;done:return r+2;}"; break;
      case 3: source="I64i Twice(I64i x=21){return x*2;}I64i Main(){return Twice;}"; break;
      case 4: source="I64i Fact(I64i n){if(n<2)return 1;return n*Fact(n-1);}I64i Main(){return Fact(5);}"; expected=120; break;
      case 5: source="I64i Inc(I64i n){return n+1;}I64i Add(I64i a,I64i b){return a+b;}I64i Main(){return Add(Inc(19),Inc(21));}"; break;
      case 6: source="F64 Calc(I64i x){F64 y=x;return y/2.0+0.5;}I64i Main(){I64i r=Calc(83);return r;}"; break;
      case 7: source="I64i data[3]={10,20,12};I64i Main(){return data[0]+data[1]+data[2];}"; break;
      case 8: source="I64i Next(){static I64i n=20;return ++n;}I64i Main(){return Next()+Next()-1;}"; break;
      case 9: source="class Pair{I64i a,b;};Pair p={20,22};I64i Main(){return p.a+p.b;}"; break;
      case 10: source="I64i Main(){I64i good=1;Missing bad;return good;}"; break;
      case 11: source="extern I64i Later();I64i Main(){return Later();}"; break;
      case 12: source="U8i *p=\"ABC\";U32i tag=0x12345678;I64i Main(){p[1]=42;if(sizeof(p)!=4 || tag!=0x12345678)return -1;return p[1];}"; break;
      case 20: source="U8i *p=\"\";I64i Main(){return p[0]+42;}"; break;
      case 21: source="U8i *p=\"A\\0B\" \"C\";I64i Main(){if(p[1] || p[4])return -1;return p[2]+p[3];}"; expected=133; break;
      case 22: source="I64i Next(){static U8i *p=\"AZ\";return ++p[0];}I64i Main(){return Next()+Next();}"; expected=133; break;
      case 23: source="class Strings{U8i *a;U32i tag;I8i *b;};Strings s={\"ABC\",0x12345678,\"xy\"};I64i Main(){if(sizeof(Strings)!=12 || s.tag!=0x12345678)return -1;return s.a[2]+s.b[1];}"; expected=188; break;
      case 24: source="U8i *p[]={\"ab\",\"cd\"};I64i Main(){if(sizeof(p)!=8)return -1;return p[0][1]+p[1][0];}"; expected=197; break;
      case 25: source="U8i *p=\"temporary\";Unknown bad;I64i Main(){return 42;}"; break;
      case 26: source="extern I64i Later(I64i n);I64i Main(){return Later(20)+Later(22);}I64i Later(I64i n){return n;}"; break;
      case 27: source="extern I64i Odd(I64i n);I64i Even(I64i n){if(!n)return 1;return Odd(n-1);}I64i Odd(I64i n){if(!n)return 0;return Even(n-1);}I64i Main(){return Even(12)*40+Odd(9)*2;}"; break;
      case 28: source="extern F64 Later(F64 n);I64i Main(){I64i x=Later(20.5)+Later(0.5);return x;}F64 Later(F64 n){return n*2.0;}"; break;
      case 29: source="extern I64i Later(I64i n);I64i Main(){return Later(42);}I64i Later(){return 42;}"; break;
      case 30: source="extern I64i Later();I64i Main(){return Later();}F64 Later(){return 42.0;}"; break;
      case 31: source="extern I64i Later(I64i n);I64i Main(){return Later(42);}Unknown bad;"; break;
      case 32: source="extern I64i Later(I64i n);I64i Main(){return Later(40);}I64i Later(I64i n){I64i a[1+1];a[0]=n;a[1]=2;return a[0]+a[1];}"; break;
      case 33: source="extern I64i Later(I64i n);I64i Main(){return Later(42);}I64i Later(F64 n){return 42;}"; break;
      case 14: source="I64i Main(){I64i n=5;static I64i x=n;return x;}"; break;
      case 15: source="I64i Inc(I64i x){return x+1;}I64i Main(){I64i (*f)(I64i x);f=&Inc;return f(41);}"; break;
      case 16: source="I64i Count(...){return argc;}I64i Main(){return Count(1,2,3);}"; expected=3; break;
      case 17: source="I64i Main(){I64i reg x=42;return x;}"; break;
      case 19: source="I64i Main(){goto missing;return 42;}"; break;
      case 18: source="I64i Main(){I64i reg R8 x=42;return x;}"; break;
    }
    source_flags=CCF_DONT_FREE_BUF|CCF_AOT_COMPILE;
    if(kind==13) {
      deep=I386HeapAlloc(heap,1100,TRUE); if(!deep) KernelStop;
      source="I64i Main(){"; length=0;
      while(source[length]) { deep[length]=source[length]; length++; }
      for(i=0;i<512;i++) deep[length++]='{';
      source="return 42;"; i=0;
      while(source[i]) deep[length++]=source[i++];
      for(i=0;i<513;i++) deep[length++]='}';
      source=deep; source_flags=CCF_AOT_COMPILE;
    }
    cc=probe->files->control_new(source,source_flags,"Probe/Statements.HC");
    if(!cc || !probe->compiler->control_enter(heap,cc,0,0)) KernelStop;
    symbols=probe->compiler->frontend(heap,cc,probe->internal_types,probe->disk_include);
    if(!symbols) KernelStop;
    expression=symbols->declarations->expression;
    expression->report=&ProbeExpressionReport;
    symbols->declarations->types->report=&ProbeExpressionReport;
    KernelLog("STATEMENT START "); KernelHex(kind); KernelLog("\n"); accepted=0;
    try {
      expression->lex(expression->context,cc); count=0;
      while(cc->token!=TK_EOF) {
        if(++count>32 || !probe->compiler->statement(heap,cc,symbols,CMPF_PRS_SEMICOLON)) KernelStop;
      }
      if((kind==10 || kind==13 || kind==14 || kind==18 || kind==19 || kind==25 || kind==29 || kind==30 || kind==31 || kind==33)) KernelStop;
      main_fun=ProbeSymbolFind(0,"Main",cc->htc.glbl_hash_table,HTT_FUN);
      if(!main_fun || !main_fun->exe_addr || Bt(&main_fun->flags,Cf_EXTERN)) KernelStop;
      entry=main_fun->exe_addr; actual=(*entry)();
      KernelLog("STATEMENT VALUE "); KernelHex(actual); KernelLog("\n");
      if(actual!=expected) KernelStop;
      accepted=1;
    } catch {
      if(!((kind==10 || kind==11 || kind==13 || kind==14 || kind==18 || kind==19 || kind==25 || kind==29 || kind==30 || kind==31 || kind==33)) || task->except_ch!='Compiler') {
        KernelLog("STATEMENT EXCEPTION "); KernelHex(kind); KernelLog(" "); KernelHex(task->except_ch); KernelLog("\n");
        KernelLog("STATEMENT TOKEN "); KernelHex(cc->token); KernelLog(" ERRORS "); KernelHex(cc->error_cnt); KernelLog("\n");
        if(cc->cur_str) { KernelLog("STATEMENT IDENTIFIER "); KernelLog(cc->cur_str); KernelLog("\n"); }
        if(cc->htc.fun) { KernelLog("STATEMENT FUNCTION "); KernelLog(cc->htc.fun->str); KernelLog("\n"); }
        for(node=cc->coc.coc_head.next;node!=&cc->coc.coc_head;node=node->next) {
          KernelLog("STATEMENT IR "); KernelHex(node->ic_code); KernelLog(" "); KernelHex(node->ic_data); KernelLog("\n");
        }
        KernelStop;
      }
      task->catch_except=TRUE; accepted=1;
    }
    if(!accepted || !probe->compiler->control_unwind(task,outer)) { KernelLog("STATEMENT UNWIND REJECT\n"); KernelStop; }
    if(task->last_cc!=outer || task->active_controls!=1 || task->lifetime_refs!=refs || task->except_top ||
        heap->used!=used || heap->allocations!=allocations || !I386HeapValid(heap) ||
        (GetRFlags&0x200)!=(flags&0x200)) { KernelLog("STATEMENT OWNERSHIP REJECT\n"); KernelStop; }
    KernelLog("STATEMENT CASE "); KernelHex(probe->phase); KernelLog(" "); KernelHex(kind); KernelLog("\n");
  }
}
