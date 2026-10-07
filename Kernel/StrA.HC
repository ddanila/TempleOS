U8 *StrPrintHex(U8 *dst,I64 num;I64 width)
{
  U8 *res=dst+width;
  dst=res;
  while (width--) {
    *--dst="0123456789ABCDEF"(U8 *)[num&15];
    num>>=4;
  }
  return res;
}

U0 PutHex(I64 num,I64 width)
{
  U8 buf[17];
  if (width>16) width=16;
  *StrPrintHex(buf,num,width)=0;
  "%s",buf;
}

asm {
// IN:	RAX=NUM TO PRINT
PUT_HEX_U64::
	PUSH_C_REGS
	PUSH	16
	PUSH	RAX
	CALL	&PutHex
	POP_C_REGS
	RET
PUT_HEX_U32::
	PUSH_C_REGS
	PUSH	8
	PUSH	RAX
	CALL	&PutHex
	POP_C_REGS
	RET
PUT_HEX_U16::
	PUSH_C_REGS
	PUSH	4
	PUSH	RAX
	CALL	&PutHex
	POP_C_REGS
	RET
PUT_HEX_U8::
	PUSH_C_REGS
	PUSH	2
	PUSH	RAX
	CALL	&PutHex
	POP_C_REGS
	RET
PUT_CHARS::
// IN:	RAX=Char
	PUSH_C_REGS
	PUSH	RAX
	CALL	&PutChars
	POP_C_REGS
	RET
PUT_STR::
// IN:	RSI=String
	PUSH_C_REGS
	PUSH	RSI
	CALL	&PutS
	POP_C_REGS
	RET
_STRCPY::
	PUSH	RBP
	MOV	RBP,RSP
	PUSH	RSI
	PUSH	RDI
	MOV	RDI,U64 SF_ARG1[RBP]
	TEST	RDI,RDI
	JZ	@@15
	MOV	RSI,U64 SF_ARG2[RBP]
	TEST	RSI,RSI
	JNZ	@@05
	XOR	RAX,RAX
	JMP	@@10
@@05:	LODSB
@@10:	STOSB
	TEST	AL,AL
	JNZ	@@05
@@15:	POP	RDI
	POP	RSI
	POP	RBP
	RET1	16
_STRCMP::
	PUSH	RBP
	MOV	RBP,RSP
	PUSH	RSI
	PUSH	RDI
	MOV	RSI,U64 SF_ARG2[RBP]
	MOV	RDI,U64 SF_ARG1[RBP]
@@05:	LODSB
	TEST	AL,AL
	JZ	@@20
	SCASB
	JE	@@05
	JA	@@15
@@10:	MOV	RAX,1
	JMP	@@25
@@15:	MOV	RAX,-1
	JMP	@@25
@@20:	SCASB
	JNE	@@10
	XOR	RAX,RAX
@@25:	POP	RDI
	POP	RSI
	POP	RBP
	RET1	16
TO_UPPER::
	CMP	AL,'a'
	JB	@@05
	CMP	AL,'z'
	JA	@@05
	ADD	AL,'A'-'a'
@@05:	RET
_STRICMP::
	PUSH	RBP
	MOV	RBP,RSP
	PUSH	RSI
	PUSH	RDI
	MOV	RSI,U64 SF_ARG2[RBP]
	MOV	RDI,U64 SF_ARG1[RBP]
@@05:	LODSB
	TEST	AL,AL
	JZ	@@30
	CMP	AL,'a'
	JB	@@10
	CMP	AL,'z'
	JA	@@10
	ADD	AL,'A'-'a'
@@10:	MOV	BL,U8 [RDI]
	INC	RDI
	CMP	BL,'a'
	JB	@@15
	CMP	BL,'z'
	JA	@@15
	ADD	BL,'A'-'a'
@@15:	CMP	AL,BL
	JE	@@05
	JA	@@25
@@20:	MOV	RAX,1
	JMP	@@35
@@25:	MOV	RAX,-1
	JMP	@@35
@@30:	MOV	BL,U8 [RDI]
	TEST	BL,BL
	JNE	@@20
	XOR	RAX,RAX
@@35:	POP	RDI
	POP	RSI
	POP	RBP
	RET1	16
_STRNCMP::
	PUSH	RBP
	MOV	RBP,RSP
	PUSH	RSI
	PUSH	RDI
	MOV	RCX,U64 SF_ARG3[RBP]
	MOV	RSI,U64 SF_ARG2[RBP]
	MOV	RDI,U64 SF_ARG1[RBP]
@@05:	TEST	RCX,RCX
	JZ	@@25
	DEC	RCX
	LODSB
	TEST	AL,AL
	JZ	@@20
	SCASB
	JE	@@05
	JA	@@15
@@10:	MOV	RAX,1
	JMP	@@30
@@15:	MOV	RAX,-1
	JMP	@@30
@@20:	MOV	BL,U8 [RDI]
	TEST	BL,BL
	JNE	@@10
@@25:	XOR	RAX,RAX
@@30:	POP	RDI
	POP	RSI
	POP	RBP
	RET1	24
_STRNICMP::
	PUSH	RBP
	MOV	RBP,RSP
	PUSH	RSI
	PUSH	RDI
	MOV	RCX,U64 SF_ARG3[RBP]
	MOV	RSI,U64 SF_ARG2[RBP]
	MOV	RDI,U64 SF_ARG1[RBP]
@@05:	TEST	RCX,RCX
	JZ	@@35
	DEC	RCX
	LODSB
	TEST	AL,AL
	JZ	@@30
	CMP	AL,'a'
	JB	@@10
	CMP	AL,'z'
	JA	@@10
	ADD	AL,'A'-'a'
@@10:	MOV	BL,U8 [RDI]
	INC	RDI
	CMP	BL,'a'
	JB	@@15
	CMP	BL,'z'
	JA	@@15
	ADD	BL,'A'-'a'
@@15:	CMP	AL,BL
	JE	@@05
	JA	@@25
@@20:	MOV	RAX,1
	JMP	@@40
@@25:	MOV	RAX,-1
	JMP	@@40
@@30:	SCASB
	JNE	@@20
@@35:	XOR	RAX,RAX
@@40:	POP	RDI
	POP	RSI
	POP	RBP
	RET1	24
_STRMATCH::
	PUSH	RBP
	MOV	RBP,RSP
	PUSH	RSI
	PUSH	RDI
	MOV	RSI,U64 SF_ARG2[RBP]
	TEST	RSI,RSI
	JZ	@@25
	MOV	RDI,U64 SF_ARG1[RBP]
	TEST	RDI,RDI
	JZ	@@25
	MOV	DL,U8 [RDI]
	TEST	DL,DL
	JZ	@@20
	JMP	@@10
@@05:	INC	RSI
@@10:	LODSB
	TEST	AL,AL
	JZ	@@25
	CMP	AL,DL
	JNE	@@10
	DEC	RSI
	MOV	RCX,1
@@15:	MOV	AL,U8 [RDI+RCX]
	TEST	AL,AL
	JZ	@@20
	CMP	AL,U8 [RSI+RCX]
	JNE	@@05
	INC	RCX
	JMP	@@15

	DEC	RSI
@@20:	MOV	RAX,RSI
	JMP	@@30
@@25:	XOR	RAX,RAX
@@30:	POP	RDI
	POP	RSI
	POP	RBP
	RET1	16
_STRIMATCH::
	PUSH	RBP
	MOV	RBP,RSP
	PUSH	RSI
	PUSH	RDI
	MOV	RSI,U64 SF_ARG2[RBP]
	TEST	RSI,RSI
	JZ	@@25
	MOV	RDI,U64 SF_ARG1[RBP]
	TEST	RDI,RDI
	JZ	@@25
	MOV	AL,U8 [RDI]
	CALL	TO_UPPER
	MOV	DL,AL
	TEST	DL,DL
	JZ	@@20
	JMP	@@10
@@05:	INC	RSI
@@10:	LODSB
	CALL	TO_UPPER
	TEST	AL,AL
	JZ	@@25
	CMP	AL,DL
	JNE	@@10
	DEC	RSI
	MOV	RCX,1
@@15:	MOV	AL,U8 [RDI+RCX]
	CALL	TO_UPPER
	TEST	AL,AL
	JZ	@@20
	MOV	BL,U8 [RSI+RCX]
	XCHG	AL,BL
	CALL	TO_UPPER
	CMP	AL,BL
	JNE	@@05
	INC	RCX
	JMP	@@15

	DEC	RSI
@@20:	MOV	RAX,RSI
	JMP	@@30
@@25:	XOR	RAX,RAX
@@30:	POP	RDI
	POP	RSI
	POP	RBP
	RET1	16
}
_extern _STRCMP I64 StrCmp(
	U8 *st1,U8 *st2); //Compare two strings.
_extern _STRICMP I64 StrICmp(
	U8 *st1,U8 *st2); //Compare two strings, ignoring case.
_extern _STRNCMP I64 StrNCmp(
	U8 *st1,U8 *st2,I64 n); //Compare N bytes in two strings.
_extern _STRNICMP I64 StrNICmp(
	U8 *st1,U8 *st2,I64 n); //Compare N bytes in two strings, ignoring case.
_extern _STRMATCH U8 *StrMatch(
	U8 *needle,U8 *haystack_str); //Scan for string in string.
_extern _STRIMATCH U8 *StrIMatch(
	U8 *needle,U8 *haystack_str);//Scan for string in string, ignoring case.
_extern _STRCPY U0 StrCpy(
	U8 *dst,U8 *src); //Copy string.

#include "/Kernel/CharBitmaps.HC"

#include "/Kernel/ListCore.HC"

#include "/Kernel/StringUtilCore.HC"

#include "/Kernel/StringTailCore.HC"

U8 *StrFind(U8 *needle,U8 *haystack_str,I64 flags=0)
{//Find needle_str in haystack_str with options.
  Bool cont;
  U8 *saved_haystack_str=haystack_str;
  I64 plen=StrLen(needle);
  do {
    cont=FALSE;
    if (flags & SFF_IGNORE_CASE)
      haystack_str=StrIMatch(needle,haystack_str);
    else
      haystack_str=StrMatch(needle,haystack_str);
    if (haystack_str && flags & SFF_WHOLE_LABELS_BEFORE &&
	  haystack_str!=saved_haystack_str &&
	  Bt(char_bmp_alpha_numeric,*(haystack_str-1))) {
      haystack_str++;
      if (*haystack_str)
	cont=TRUE;
      else
	haystack_str=NULL;
    }
    if (haystack_str && flags & SFF_WHOLE_LABELS_AFTER &&
	  Bt(char_bmp_alpha_numeric,*(haystack_str+plen))) {
      haystack_str++;
      if (*haystack_str)
	cont=TRUE;
      else
	haystack_str=NULL;
    }
  } while (cont);
  return haystack_str;
}

#include "/Kernel/WildMatchCore.HC"
