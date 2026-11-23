#ifndef I386_PUBLIC_REGISTRY_INCLUDED
#define I386_PUBLIC_REGISTRY_INCLUDED
public _extern _REG_CACHE Bool RegCache();
public _extern _REG_DFT Bool RegDft(U8 *path,U8 *val,Bool is_adam_entry=FALSE);
public _extern _REG_EXE I64 RegExe(U8 *path);
public _extern _REG_WRITE Bool RegWrite(U8 *path,U8 *fmt,...);
public _extern _REG_CNT I64 RegCnt(U8 *path);
public _extern _REG_APPEND Bool RegAppend(U8 *path,U8 *fmt,...);
public _extern _REG_INIT U0 RegInit();
public _extern _SYS_REGISTRY_DOC CDoc *sys_registry_doc;
public _extern _SYS_MSG_FLAGS I64 sys_msg_flags[1];
public _extern _REGISTRY_VERSION F64 registry_version;
public _extern _NATIVE_REGISTRY_INIT U0 NativeRegistryInit();
#define ARf_FLOODFILL			0
#define ARf_CSPRITE_INS_CLIP		1
#define ARf_PLANAR_SYMMETRY		2
#define ARf_PSALMODY_JUKEBOX		3
#define ARf_MESH_ED			4
#define ARf_CSPRITE_PTS_RECTANGLES	5
#define ARf_MANAGE_SLIDER		6

public _extern _ONE_TIME_POP_UP Bool OneTimePopUp(U8 *flags,I64 flag_num,U8 *msg);
public _extern _REG_ONE_TIME_POP_UP U0 RegOneTimePopUp(I64 flag_num,U8 *msg);
#endif
