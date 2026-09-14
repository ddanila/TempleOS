#ifndef PRS_PRECEDENCE_INCLUDED
#define PRS_PRECEDENCE_INCLUDED
#define ASSOCF_LEFT	1
#define ASSOCF_RIGHT	2
#define ASSOC_MASK	3

#define PREC_NULL		0x00
#define PREC_TERM		0x04
#define PREC_UNARY_POST		0x08
#define PREC_UNARY_PRE		0x0C
#define PREC_EXP		0x10
#define PREC_MUL		0x14
#define PREC_AND		0x18
#define PREC_XOR		0x1C
#define PREC_OR			0x20
#define PREC_ADD		0x24
#define PREC_CMP		0x28
#define PREC_CMP2		0x2C
#define PREC_AND_AND		0x30
#define PREC_XOR_XOR		0x34
#define PREC_OR_OR		0x38
#define PREC_ASSIGN		0x3C

#define PREC_MAX		0x40
#endif
