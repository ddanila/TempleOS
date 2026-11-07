Bool Option(I64 num,Bool val)
{//Set compiler $LK,"Option",A="FI:::/Doc/Options.DD"$ to val.
  return BEqu(&Fs->last_cc->opts,num,val);
}

Bool GetOption(I64 num)
{//Get state of compiler $LK,"option",A="MN:OPTf_ECHO"$.
  return Bt(&Fs->last_cc->opts,num);
}

asm {
_LAST_FUN::	//See $LK,"_CALL_IND",A="MN:_CALL_IND"$
	PUSH	RBP
	MOV	RBP,RSP
	PUSH	RSI
	PUSH	RDI

	XOR	RAX,RAX
	MOV	RAX,FS:CTask.last_fun[RAX]
	TEST	RAX,RAX
	JZ	@@10
	MOV	RDX,U64 CHashFun.exe_addr[RAX]

	MOV	RCX,U64 SF_ARG1[RBP]	//argc
	MOV	RSI,U64 SF_ARG2[RBP]	//argv
	SHL	RCX,3
	SUB	RSP,RCX
	MOV	RDI,RSP
	REP_MOVSB
	TEST	RDX,RDX
	JZ	@@05

	CALL	RDX
	POP	RDI
	POP	RSI
	POP	RBP
	RET1	16

@@05:	MOV	RCX,U64 SF_ARG1[RBP]	//argc
	SHL	RCX,3
	ADD	RSP,RCX
	XOR	RAX,RAX
@@10:	POP	RDI
	POP	RSI
	POP	RBP
	RET1	16
}
_extern _LAST_FUN I64 LastFun(I64 argc,I64 *argv); //Execute last fun with args.

I64 PassTrace(I64 i=0b10001111101)
{//Ctrls which optimizer passes are displayed.
  I64 old=Fs->last_cc->pass_trace;
  if (i) Fs->last_cc->saved_pass_trace=i;
  Fs->last_cc->pass_trace=i;
  return old;
}

Bool Trace(Bool val=ON)
{//Displays assembly code output from compiler.
  return Option(OPTf_TRACE,val);
}

Bool Echo(Bool val)
{//Displays text as it is being compiled.
  return Option(OPTf_ECHO,val);
}

U0 StreamPrint(U8 *fmt,...)
{//Injects text into the compile stream. Used in #exe{} blocks.
  U8 *buf=StrPrintJoin(NULL,fmt,argc,argv),*st;
  CCmpCtrl *cc=Fs->last_cc;
  CStreamBlk *tmpe=cc->last_stream_blk;
  if (tmpe!=&cc->next_stream_blk) {
    st=MStrPrint("%s%s",tmpe->body,buf);
    Free(tmpe->body);
    tmpe->body=st;
  } else
    PrintErr("No exe{} blk\n");
  Free(buf);
}

U0 StreamDir()
{
  U8 *dirname;
  if (dirname=DirFile(Fs->last_cc->lex_include_stk->full_name)) {
    StreamPrint("\"%s\"",dirname);
    Free(dirname);
  }
}

CD2I32 *LexD2I32(CCmpCtrl *cc,CD2I32 *p)
{//Not HolyC. Sprite-like lex 2D point.
  if (cc->token!='(')
    LexExcept(cc,"Expecting '(' at ");
  Lex(cc); //Skip (
  p->x=LexExpressionI64(cc);
  if (cc->token!=',')
    LexExcept(cc,"Expecting ',' at ");
  Lex(cc); //Skip ,
  p->y=LexExpressionI64(cc);
  if (cc->token!=')')
    LexExcept(cc,"Expecting ')' at ");
  Lex(cc); //Skip )
  return p;
}

CD3I32 *LexD3I32(CCmpCtrl *cc,CD3I32 *p)
{//Not HolyC. Sprite-like lex 3D point.
  if (cc->token!='(')
    LexExcept(cc,"Expecting '(' at ");
  Lex(cc); //Skip (
  p->x=LexExpressionI64(cc);
  if (cc->token!=',')
    LexExcept(cc,"Expecting ',' at ");
  Lex(cc); //Skip ,
  p->y=LexExpressionI64(cc);
  if (cc->token!=',')
    LexExcept(cc,"Expecting ',' at ");
  Lex(cc); //Skip ,
  p->z=LexExpressionI64(cc);
  if (cc->token!=')')
    LexExcept(cc,"Expecting ')' at ");
  Lex(cc); //Skip )
  return p;
}

#include "/Compiler/CommandPromptCore.HC"
