#ifndef FILE_MASK_TYPES_INCLUDED
#define FILE_MASK_TYPES_INCLUDED
#define FILEMASK_JIT	"*.HC*;*.HH*"
#define FILEMASK_AOT	"*.HC*;*.HH*;*.PRJ*"
#define FILEMASK_SRC	"*.HC*;*.HH*;*.IN*;*.PRJ*"
#define FILEMASK_DD	FILEMASK_SRC ";*.DD*"
#define FILEMASK_TXT	FILEMASK_DD ";*.TXT*"
#define FILEMASK_GR	"*.GR*"

#define FUf_JUST_TXT		12
#define FUf_JUST_DD		13
#define FUf_JUST_SRC		14
#define FUf_JUST_AOT		15
#define FUf_JUST_JIT		16
#define FUf_JUST_GR		17
#define FUF_JUST_TXT		0x0001000 //T
#define FUF_JUST_DD		0x0002000 //$$
#define FUF_JUST_SRC		0x0004000 //S
#define FUF_JUST_AOT		0x0008000 //A
#define FUF_JUST_JIT		0x0010000 //J
#define FUF_JUST_GR		0x0020000 //G
#endif
