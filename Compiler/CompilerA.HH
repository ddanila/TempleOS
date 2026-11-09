#ifndef COMPILER_A_INCLUDED
#define COMPILER_A_INCLUDED
#help_index "Compiler/Internal"
//Intermediate compiler codes
#define IS_0_ARG	0
#define IS_1_ARG	1
#define IS_2_ARG	2
#define IS_V_ARG	3 //Variable Arg Cnt

#define IST_NULL	0
#define IST_DEREF	1
#define IST_ASSIGN	2
#define IST_CMP		3
	
class CIntermediateStruct
{
  U8 arg_cnt,res_cnt,type;
  Bool fpop,not_const,pad[3];
  U8 *name;
};

#include "/Compiler/IntermediateOpcodes.HH"

#include "/Compiler/Keywords.HH"

#define CMP_TEMPLATE_INC	0x00
#define CMP_TEMPLATE_DEC	0x01
#define CMP_TEMPLATE_MOD	0x02
#define CMP_TEMPLATE_LESS	0x03
#define CMP_TEMPLATE_GREATER	0x04
#define CMP_TEMPLATE_LESS_EQU	0x05
#define CMP_TEMPLATE_GREATER_EQU 0x06
#define CMP_TEMPLATE_STRLEN	0x07
#define CMP_TEMPLATE_RDTSC	0x08
#define CMP_TEMPLATE_SIGN_I64	0x09
#define CMP_TEMPLATE_FSTP	0x0A
#define CMP_TEMPLATE_FLD	0x0B
#define CMP_TEMPLATE_SQR	0x0C
#define CMP_TEMPLATE_ABS	0x0D
#define CMP_TEMPLATE_SQRT	0x0E
#define CMP_TEMPLATE_SIN	0x0F
#define CMP_TEMPLATE_COS	0x10
#define CMP_TEMPLATE_TAN	0x11
#define CMP_TEMPLATE_ATAN	0x12

#include "/Compiler/PrsPrecedence.HH"

#include "/Compiler/PrsFunctionFlags.HH"

#include "/Compiler/PrsTypeFlags.HH"

class COptReg
{
  I64	offset;
  CMemberLst *m;
};

#include "/Compiler/PrsCompileFlags.HH"

#help_index ""

#endif
