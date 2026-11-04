#ifndef FILE_UTILITY_FLAGS_INCLUDED
#define FILE_UTILITY_FLAGS_INCLUDED
#include "/Kernel/FileMaskTypes.HH"
#include "/Kernel/FileFindFlags.HH"
#define FUf_RECURSE		0
#define FUf_DIFF		1
#define FUf_DEL			1
#define FUf_IGNORE		2
#define FUf_ALL			3
#define FUf_CANCEL		4
#define FUf_REPLACE		5
#define FUf_RISKY		5
#define FUf_PUBLIC		6
#define FUf_MAP			7
#define FUf_EXPAND		8
#define FUf_SINGLE		9
#define FUf_JUST_DIRS		10
#define FUf_JUST_FILES		11
#define FUf_Z_OR_NOT_Z		18
#define FUf_CLUS_ORDER	19
#define FUf_SCAN_PARENTS	20
#define FUf_FLATTEN_TREE	21
#define FUf_WHOLE_LABELS	22
#define FUf_WHOLE_LABELS_BEFORE	23
#define FUf_WHOLE_LABELS_AFTER	24

#define FUF_RECURSE		0x0000001 //r
#define FUF_DIFF		0x0000002 //d
#define FUF_DEL			0x0000002 //d
#define FUF_IGNORE		0x0000004 //i
#define FUF_ALL			0x0000008 //a
#define FUF_CANCEL		0x0000010 //c
#define FUF_REPLACE		0x0000020 //R
#define FUF_RISKY		0x0000020 //R
#define FUF_PUBLIC		0x0000040 //p
#define FUF_MAP			0x0000080 //m
#define FUF_EXPAND		0x0000100 //x
#define FUF_SINGLE		0x0000200 //s
#define FUF_CLUS_ORDER	0x0080000 //O Move disk head one direction
#define FUF_FLATTEN_TREE	0x0200000 //f
#define FUF_WHOLE_LABELS	0x0400000 //l
#define FUF_WHOLE_LABELS_BEFORE	0x0800000 //lb
#define FUF_WHOLE_LABELS_AFTER	0x1000000 //la

#define FUG_FILES_FIND	(FUF_RECURSE|FUF_SINGLE|FUF_CLUS_ORDER|\
  FUF_JUST_DIRS|FUF_JUST_FILES|FUF_JUST_TXT|FUF_JUST_DD|\
  FUF_JUST_SRC|FUF_JUST_AOT|FUF_JUST_JIT|FUF_JUST_GR|FUF_FLATTEN_TREE)
#endif
