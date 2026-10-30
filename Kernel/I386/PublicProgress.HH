#ifndef I386_PUBLIC_PROGRESS_INCLUDED
#define I386_PUBLIC_PROGRESS_INCLUDED
#include "/Kernel/I386/ProgressTypes.HH"
public _extern SYS_PROGRESS1 I64 progress1;
public _extern SYS_PROGRESS1_MAX I64 progress1_max;
public _extern SYS_PROGRESS1_T0 F64 progress1_t0;
public _extern SYS_PROGRESS1_TF F64 progress1_tf;
public _extern SYS_PROGRESS1_DESC U8 progress1_desc[PROGRESS_DESC_LEN];
public _extern SYS_PROGRESS2 I64 progress2;
public _extern SYS_PROGRESS2_MAX I64 progress2_max;
public _extern SYS_PROGRESS2_T0 F64 progress2_t0;
public _extern SYS_PROGRESS2_TF F64 progress2_tf;
public _extern SYS_PROGRESS2_DESC U8 progress2_desc[PROGRESS_DESC_LEN];
public _extern SYS_PROGRESS3 I64 progress3;
public _extern SYS_PROGRESS3_MAX I64 progress3_max;
public _extern SYS_PROGRESS3_T0 F64 progress3_t0;
public _extern SYS_PROGRESS3_TF F64 progress3_tf;
public _extern SYS_PROGRESS3_DESC U8 progress3_desc[PROGRESS_DESC_LEN];
public _extern SYS_PROGRESS4 I64 progress4;
public _extern SYS_PROGRESS4_MAX I64 progress4_max;
public _extern SYS_PROGRESS4_T0 F64 progress4_t0;
public _extern SYS_PROGRESS4_TF F64 progress4_tf;
public _extern SYS_PROGRESS4_DESC U8 progress4_desc[PROGRESS_DESC_LEN];
public _extern SYS_PROGRESSES CProgress sys_progresses[PROGRESS_BARS_NUM];
#endif
