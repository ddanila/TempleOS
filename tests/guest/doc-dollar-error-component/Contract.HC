#include "::/Probe/Services.HH"
#define PrsDocFlagSingleCore DEFlagOne
#define PrsDocFlagsCore DEFlags
#define PrsDollarErrorEntryCore DEError
#define PrsDollarCmdCore DEParser
#include "::/Probe/FlagsCore.HC"
#include "::/Probe/ParseCore.HC"
U0 DELog(U8 *text){while(*text)OutU8(0xE9,*text++);}
I64 DELex(U8 *context,CCmpCtrl *cc){return Lex(cc);}
I64 DEExpression(U8 *context,CCmpCtrl *cc){if(context)throw('Compiler');return LexExpression(cc);}
U8 *DEString(U8 *context,CCmpCtrl *cc){return LexExtStr(cc);}
U0 DECheck()
{
  I64 *rows=CAlloc(40*8),*r,i,used,code;U8 *source,*text;
  CCmpCtrl *cc;CDoc *doc;CDocEntry *entry;CDocDollarServices services;
  services.lex=&DELex;services.expression=&DEExpression;services.integer_expression=&DEExpression;services.string=&DEString;
  for(i=0;i<8;i++) {
    if(i==0 || i==2)source="BT,\"bad\",A=\"aux\",D=\"def\",HTML=\"web\",LM=\"left\",RM=\"right\",LE=7";
    else if(i==1)source="BT,\"bad\",LE=7";
    else if(i==3)source="BT,\"bad\",LE";
    else if(i==4)source="BT,\"bad\",A=\"aux\",D=\"def\",HTML=\"web\",LM=\"left\",RM=\"right\",LE";
    else if(i==5)source="UNKNOWN_DOC_COMMAND";
    else if(i==6)source="BT,\"bad\",BI=1,LE";
    else source="BT,\"bad\",BI=1,LE=7";
    r=rows+i*5;used=Fs->data_heap->used_u8s;code=Fs->code_heap->used_u8s;
    doc=DocNew;cc=CmpCtrlNew(StrNew(source));services.context=NULL;
    if(i==1 || i==2 || i==7)services.context=1;
    entry=DEParser(&services,cc,doc,source);
    if(i==0)r[0]=entry && entry->type_u8==DOCT_BTTN && entry->left_exp==7 &&
      !StrCmp(entry->tag,"bad") && !StrCmp(entry->aux_str,"aux") && !StrCmp(entry->define_str,"def") &&
      !StrCmp(entry->html_link,"web") && !StrCmp(entry->left_macro,"left") && !StrCmp(entry->right_macro,"right");
    else r[0]=entry && entry->type_u8==DOCT_ERROR;
    if(i==0){r[1]=1;r[2]=1;}
    else {r[1]=!entry->de_flags;r[2]=!entry->tag;}
    QueInit(entry);DocEntryDel(doc,entry);CmpCtrlDel(cc);DocDel(doc);
    r[3]=Fs->data_heap->used_u8s-used;r[4]=Fs->code_heap->used_u8s-code;
  }
  text=MStrPrint("EXPORT dollar-component.bin %X 140\n",rows);DELog(text);Free(text);
  DELog("DOLLAR ERROR COMPONENT DONE\n");Sleep(1000);
}DECheck;
