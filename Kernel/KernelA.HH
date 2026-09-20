// Main TempleOS header

#help_index ""
extern class CAOT;
extern class CAOTHeapGlbl;
extern class CAOTImportExport;
extern class CCPU;
extern class CDC;
extern class CDirContext;
extern class CDoc;
extern class CFile;
extern class CHashClass;
extern class CHashFun;
extern class CHeapCtrl;
extern class CIntermediateCode;
extern class CJobCtrl;
extern class CTask;

#define NULL	0
#define TRUE	1
#define FALSE	0
#define ON	1
#define OFF	0
#include "/Kernel/NumericLimits.HH"
#define INVALID_PTR	I64_MAX
#include "/Kernel/StringLimits.HH"

//(Int to F64 conversion is signed)
//Turn off 80-bit float constants with $LK,"OPTf_NO_BUILTIN_CONST",A="MN:OPTf_NO_BUILTIN_CONST"$.
#define U64_F64_MAX (0x43F0000000000000(F64))
#define F64_MAX (0x7FEFFFFFFFFFFFFF(F64))
#define F64_MIN (0xFFEFFFFFFFFFFFFF(F64))
#define inf	(0x7FF0000000000000(F64))
#define ì	(0x7FF0000000000000(F64))
#define pi	(0x400921FB54442D18(F64))
#define ã	(0x400921FB54442D18(F64))
#define exp_1	(0x4005BF0A8B145769(F64)) //The number "e"
#define log2_10 (0x400A934F0979A371(F64))
#define log2_e	(0x3FF71547652B82FE(F64))
#define log10_2	(0x3FD34413509F79FF(F64))
#define loge_2	(0x3FE62E42FEFA39EF(F64))
#define sqrt2	(0x3FF6A09E667F3BCD(F64))
#define eps	(0x3CB0000000000000(F64))

#include "/Kernel/Types.HH"

#help_index "Math/Complex;Data Types/Complex"
public class Complex
{
  F64	x,y;
};

#include "/Kernel/QueueTypes.HH"

#help_index "Graphics/Data Types/D3I32;Math/Data Types/D3I32;Data Types/D3I32"
public class CD3I32 //Three dimensional I32 pt
{
  I32	x,y,z;
};
public class CQueD3I32 //Que of three dimensional I32 pts
{
  CQueD3I32	*next,*last;
  CD3I32	p;
};
#help_index "Math/Data Types;Data Types"
public class CD2I32 //Two dimensional I32 pt
{
  I32	x,y;
};
public class CD2I64 //Two dimensional I64 pt
{
  I64	x,y;
};
public class CD3I64 //Three dimensional I64 pt
{
  I64	x,y,z;
};
public class CD2 //Two dimensional F64 pt
{
  F64	x,y;
};

#help_index "Math/CD3;Data Types/CD3"
public class CD3 //Three dimensional F64 pt
{
  F64	x,y,z;
};

#help_index "Data Types/Queue Vector"
#define QUE_VECT_U8_CNT		512
public class CQueVectU8
{
  CQueVectU8	*next,*last;
  I64	total_cnt,node_cnt,min_idx;
  U8	body[QUE_VECT_U8_CNT];
};

#help_index "Data Types/Fifo"
public class CFifoU8
{
  U8	*buf;
  I64	mask,in_ptr,out_ptr;
};
public class CFifoI64
{
  I64	*buf;
  I64	mask,in_ptr,out_ptr;
};

#help_index "Date/CDate"
#define CDATE_YEAR_DAYS		365.24225
#define CDATE_YEAR_DAYS_INT	36524225
#define CDATE_BASE_DAY_OF_WEEK	0
public I64 class CDate
{
  U32	time;
  I32	date;
};

#help_index "Date;Date/CDate"
public class CDateStruct
{
  U8	sec10000,sec100,sec,min,hour,
	day_of_week,day_of_mon,mon;
  I32	year;
};

#help_index "Math/ODE"
public class COrder2D3
{
  F64	x,y,z,
	DxDt,DyDt,DzDt;
};

#define MSF_INACTIVE		1
#define MSF_FIXED		2
public class CMass
{
  CMass	*next,*last;
  COrder2D3 *state, //Point to entries in $LK,"CMathODE",A="MN:CMathODE"$.state[]
	*DstateDt;  //Point to entries in $LK,"CMathODE",A="MN:CMathODE"$.DstateDt[]

  U0	start;
  U32	flags,num;
  F64	mass,drag_profile_factor;
  U0	saved_state;
  F64	x,y,z,
	DxDt,DyDt,DzDt;
  U0	end;
};

#define SSF_INACTIVE		1
#define SSF_NO_COMPRESSION	2
#define SSF_NO_TENSION		4
public class CSpring
{
  CSpring *next,*last;
  CMass	*end1,*end2;
  F64	f,displacement; //set for you to check

  U0	start;
  U32	flags,num,
	end1_num,end2_num;
  F64	const,rest_len;
  U0	end;
};

//Ordinary Differential Equations
#define ODEF_HAS_MASSES	1
#define ODEF_PAUSED	2
#define ODEF_STARTED	4
#define ODEF_BUSY	8

#define ODEf_HAS_MASSES	0
#define ODEf_PAUSED	1
#define ODEf_STARTED	2
#define ODEf_BUSY	3

public class CMathODE
{
  CMathODE *next,*last;
  I64	flags,n,n_internal;
  CMass	*next_mass,*last_mass;
  CSpring *next_spring,*last_spring;
  F64	drag_v,  //drag proportional to velocity
	drag_v2, //drag proportional to velocity squared
	drag_v3, //drag proportional to velocity cubed
	acceleration_limit, //This clips acceleration
	base_t,
	t,t_scale,
	h,h_min,h_max;

  //This is not precise, just a ballpark.
  //TempleOS CMathODE's are for video games
  //not science.  It bails if it takes
  //too long.
  F64	min_tolerance,max_tolerance;

  F64	tolerance_internal,
	*array_base,
	*state,
	*state_internal,
	*DstateDt,
	*state_scale,
	*initial_state,
	*tmp0,*tmp1,*tmp2,*tmp3,
	*tmp4,*tmp5,*tmp6,*tmp7;
  CTask	*mem_task,*win_task;
  U0	(*derive)(CMathODE *o,F64 t,F64 *state,F64 *DstateDt);
  U0	(*mp_derive)(CMathODE *o,F64 t, //If break into parallel pieces.
		I64 cpu_num,F64 *state,F64 *DstateDt);
  CTask **slave_tasks;
  I64	mp_not_done_flags;
  F64	mp_t,*mp_state,*mp_DstateDt;

  I64	user_data;
};

#help_index "Processor"
//IDT entry types
#define IDTET_TASK		0x05
#define IDTET_IRQ		0x0E
#define IDTET_TRAP		0x0F //Same as IRQ but doesnt do CLI.

//Interrupts
//0x00-0x1F are reserved by Intel
#define I_DIV_ZERO		0x00
#define I_SINGLE_STEP		0x01
#define I_NMI			0x02
#define I_BPT			0x03
#define I_PAGE_FAULT		0x0E
//0x20-0x2F are used for hardware
#define I_TIMER			0x20
//Software Interrupts
#define I_MP_CRASH		0x30
#define I_WAKE			0x31
#define I_DBG			0x32
//See $LK,"ST_INT_NAMES",A="MN:ST_INT_NAMES"$

//You might want to start bwd from
//0xFF for your own interrupts.
#define I_USER			0x40

#define MP_PROCESSORS_NUM	128

#define SYS_START_CR0		0x0031

#define RFLAGf_CARRY		0
#define RFLAGf_PARITY		2
#define RFLAGf_AUX_CARRY	4
#define RFLAGf_ZERO		6
#define RFLAGf_SIGN		7
#define RFLAGf_TRAP		8 //Single Step
#define RFLAGf_INT		9
#define RFLAGf_DIR		10
#define RFLAGf_OVERFLOW		11
#define RFLAGf_IOPL0		12 // I/O Privilege Level
#define RFLAGf_IOPL1		13
#define RFLAGf_NESTED_TASK	14
#define RFLAGf_RESUME		16
#define RFLAGf_V8086		17
#define RFLAGf_ALIGN_CHECK	18
#define RFLAGf_VINT		19 //Virtual Interrupt
#define RFLAGf_VINT_PENDING	20
#define RFLAGf_ID		21

#define RFLAGG_START		0x0000
#define RFLAGG_NORMAL		(1<<RFLAGf_INT)

//Global Descriptor Table
class CGDTEntry
{
  U64	lo,hi;
};

class CGDT
{
  CGDTEntry null;
  CGDTEntry boot_ds;
  CGDTEntry boot_cs;
  CGDTEntry cs32;
  CGDTEntry cs64;	//The $LK,"Charter",A="FI:::/Doc/Charter.DD"$ says just ring-0.
  CGDTEntry cs64_ring3;	//$LK,"Ring3",A="FI:::/Demo/Lectures/Ring3.HC"$, in case you want to play around.
  CGDTEntry ds;
  CGDTEntry ds_ring3;
  CGDTEntry tr[MP_PROCESSORS_NUM];
  CGDTEntry tr_ring3[MP_PROCESSORS_NUM];
};

class CSysLimitBase
{
  U16	limit;	//Offset of last byte, not size.
  U8	*base;	//&GDT or &IDT
};

#help_index "Memory/Info"
#define MEM_E820_ENTRIES_NUM	48
class CMemE820
{
  U8	*base;
  I64	len;
  U8	type,pad[3];
};

#help_index "Compiler/Internal"
//Loader flags
#define LDF_NO_ABSS		1
#define LDF_JUST_LOAD		2
#define LDF_SILENT		4

#define BIN_SIGNATURE_VAL	'TOSB'
class CBinFile
{//$LK,"Bin File Header Generation",A="FF:::/Compiler/CMain.HC,16 ALIGN"$ by compiler.
  U16	jmp;
  U8	module_align_bits,
	reserved;
  U32	bin_signature;
  I64	org,
	patch_table_offset, //$LK,"Patch Table Generation",A="FF:::/Compiler/CMain.HC,IET_ABS_ADDR"$
	file_size;
};

class CPatchTableAbsAddr
{
  U8	eit_abs_addr;	//$LK,"IET_ABS_ADDR",A="MN:IET_ABS_ADDR"$
  U32	abs_addres_cnt;
  U8	zero;
  U32	abs_addres[1];
};

#include "/Kernel/PatchTypes.HH"
#help_index "Boot"
class CKernel
{//Must match $LK,"OSStartUp",A="FF:::/Kernel/KStart16.HC,MEM_BOOT_BASE"$
  CBinFile h;
  U32	jmp,
	boot_src,
	boot_blk,
	boot_patch_table_base,
	sys_run_level;
  CDate	compile_time;

  U0	start;
  U32	boot_base;
  U16	mem_E801[2];
  CMemE820 mem_E820[MEM_E820_ENTRIES_NUM];
  U64	mem_physical_space;
  CSysLimitBase sys_gdt_ptr;
  U16	sys_pci_busses;
  ;$$=($$+15)&-16;
  CGDT	sys_gdt;
};

//Run-Levels
#define RLf_16BIT		0
#define RLf_VGA			1
#define RLf_32BIT		2
#define RLf_PATCHED		3
#define RLf_16MEG_SYS_CODE_BP	4
#define RLf_64BIT		5
#define RLf_16MEG_ADAM_HEAP_CTRL 6
#define RLf_FULL_HEAPS		7
#define RLf_RAW			8
#define RLf_INTERRUPTS		9
#define RLf_BLKDEV		10
#define RLf_MP			11
#define RLf_COMPILER		12
#define RLf_DOC			13
#define RLf_WINMGR		14
#define RLf_REGISTRY		15
#define RLf_HOME		16
#define RLf_AUTO_COMPLETE	17
#define RLf_ADAM_SERVER		18
#define RLf_ONCE_ADAM		19
#define RLf_ONCE_USER		20

#define RLF_16BIT		0x000001
#define RLF_VGA			0x000002
#define RLF_32BIT		0x000004
#define RLF_PATCHED		0x000008
#define RLF_16MEG_SYS_CODE_BP	0x000010
#define RLF_64BIT		0x000020
#define RLF_16MEG_ADAM_HEAP_CTRL 0x000040
#define RLF_FULL_HEAPS		0x000050
#define RLF_RAW			0x000100
#define RLF_INTERRUPTS		0x000200
#define RLF_BLKDEV		0x000400
#define RLF_MP			0x000800
#define RLF_COMPILER		0x001000
#define RLF_DOC			0x002000
#define RLF_WINMGR		0x004000
#define RLF_REGISTRY		0x008000
#define RLF_HOME		0x010000
#define RLF_AUTO_COMPLETE	0x020000
#define RLF_ADAM_SERVER		0x040000
#define RLF_ONCE_ADAM		0x080000
#define RLF_ONCE_USER		0x100000

#help_index "Processor"
#define LAPIC_BASE		0xFEE00000

#define LAPIC_APIC_ID		(LAPIC_BASE+0x020)
#define LAPIC_APIC_VERSION	(LAPIC_BASE+0x030)
#define LAPIC_TASK_PRIORITY	(LAPIC_BASE+0x080)
#define LAPIC_ARIBITRATION_PRIORITY (LAPIC_BASE+0x090)
#define LAPIC_PROCESSOR_PRIORITY (LAPIC_BASE+0x0A0)
#define LAPIC_EOI		(LAPIC_BASE+0x0B0)
#define LAPIC_LOG_DST		(LAPIC_BASE+0x0D0)
#define LAPIC_DFR		(LAPIC_BASE+0x0E0)
#define LAPIC_LDR		(LAPIC_BASE+0x0D0)

#define LAPICF_APIC_ENABLED	0x100
#define LAPIC_SVR		(LAPIC_BASE+0x0F0)

#define LAPIC_ISR		(LAPIC_BASE+0x100)
#define LAPIC_TMR		(LAPIC_BASE+0x180)
#define LAPIC_IRR		(LAPIC_BASE+0x200)
#define LAPIC_ICR_LOW		(LAPIC_BASE+0x300)
#define LAPIC_ICR_HIGH		(LAPIC_BASE+0x310)

#define LAPIC_LVT_TIMER		(LAPIC_BASE+0x320)
#define LAPIC_LVT_THERMAL	(LAPIC_BASE+0x330)
#define LAPIC_LVT_PERF		(LAPIC_BASE+0x340)
#define LAPIC_LVT_LINT0		(LAPIC_BASE+0x350)
#define LAPIC_LVT_LINT1		(LAPIC_BASE+0x360)
#define LAPIC_LVT_ERR		(LAPIC_BASE+0x370)

#define MPN_VECT		0x97
#define MP_VECT_ADDR		(MPN_VECT*0x1000)

//I/O APIC Memory mapped window
#define IOAPIC_REG		0xFEC00000 //U8
#define IOAPIC_DATA		0xFEC00010 //U32
//I/O APIC Regs
#define IOAPICID		0x00
#define IOAPICVER		0x01
#define IOAPICARB		0x02
#define IOREDTAB		0x10

//Model specific regs.
#define IA32F_SCE	0x001
#define IA32F_LME	0x100
#define IA32_LAPIC_BASE	0x01B
#define IA32_EFER	0xC0000080
#define IA32_FS_BASE	0xC0000100
#define IA32_GS_BASE	0xC0000101

class CAP16BitInit
{//AP Multicore
  U32	jmp;
  CSysLimitBase ap_gdt_ptr;
};

#help_index "Time/CPU Cycles;Time/HPET;Time/Jiffies"
//High Performance Event Timer
#define HPET_GCAP_ID	(0xFED00000+0x00)
#define HPET_GEN_CONF	(0xFED00000+0x10)
#define HPET_MAIN_CNT	(0xFED00000+0xF0)

#include "/Kernel/TimeTypes.HH"

#help_index "Call"
//Function Stack Frame
#define SF_RBP	0x00
#define SF_RIP	0x08
#define SF_ARG1	0x10
#define SF_ARG2	0x18
#define SF_ARG3	0x20
#define SF_ARG4	0x28
#define SF_ARG5	0x30
#define SF_ARG6	0x38
#define SF_ARG7	0x40
#define SF_ARG8	0x48

class CRAXRBCRCXRDX
{
  I64	rax,rbx,rcx,rdx;
};

//Asm callable function pointers.
//They work with $LK,"CallExtNum",A="MN:CallExtNum"$() when calling from HolyC.
#define EXT_WIN_TO_TOP		0
#define EXT_WIN_FOCUS		1
#define EXT_HEAPLOG_MALLOC	2
#define EXT_HEAPLOG_FREE	3
#define EXT_DBG_RESUME		4
#define EXT_EXTS_NUM		5

#help_index "Processor"
#define DFT_CACHE_LINE_WIDTH	128

//Semaphores
class CSema
{
  Bool	val,pad[DFT_CACHE_LINE_WIDTH-1];
};
#define SEMA_DEBUG		0
#define SEMA_RECORD_MACRO	1
#define SEMA_SYS_TIMER		2
#define SEMA_SYS_DATE		3
#define SEMA_DBG_MODE		4
#define SEMA_SND		5
#define SEMA_HEAPLOG_ACTIVE	6
#define SEMA_HEAPLOG_LOCK	7
#define SEMA_REFRESH_IN_PROGRESS 8
#define SEMA_FLUSH_VGA_IMAGE	9
#define SEMA_SINGLE_USER	10
#define SEMA_DSK_CACHE		11
#define SEMA_FAR_CALL32		12
#define SEMA_DEV_MEM		13
#define SEMA_VGA		14
#define SEMA_UPDATE_WIN_Z_BUF	15
#define SEMA_TT			16
#define SEMA_MUTE		17
#define SEMA_JUST_PUMP_MSGS	18
#define SEMA_TMBEAT		19
#define SEMA_FIX		20
#define SEMA_SEMAS_NUM		21

#define CTRL_ALT_DEL		0
#define CTRL_ALT_C		1
#define CTRL_ALT_X		2
#define CTRL_ALT_TAB		3

#help_index "Hash"
#include "/Kernel/HashTypes.HH"

#include "/Kernel/SymbolTypes.HH"

#include "/Kernel/DocTypes.HH"

#help_index "Windows"
/*
Fs->win_inhibit mask

Some inhibit actions on the task itself.
Some inhibit actions if the focus task
tries to do something.
*/
#define WIF_SELF_FOCUS		0x0001 //If active this task cannot have focus
		//MENU		0x0002
#define WIF_SELF_CTRLS		0x0004
#define WIF_SELF_MS_L		0x0008
		//MS_L_D	0x0010
#define WIF_SELF_MS_R		0x0020
		//MS_R_D	0x0040
#define WIF_SELF_MS_WHEEL	0x0080 //Does nothing, yet
#define WIF_SELF_BORDER		0x0100
#define WIF_SELF_GRAB_SCROLL	0x0200
#define WIF_SELF_DOC		0x0400
#define WIF_SELF_ODE		0x0800
#define WIF_SELF_KEY_DESC	0x1000
		//FOCUS		0x00010000
#define WIF_FOCUS_TASK_MENU	0x00020000
#define WIF_FOCUS_TASK_CTRLS	0x00040000
#define WIF_FOCUS_TASK_MS_L	0x00080000
#define WIF_FOCUS_TASK_MS_L_D	0x00100000
#define WIF_FOCUS_TASK_MS_R	0x00200000
#define WIF_FOCUS_TASK_MS_R_D	0x00400000
#define WIF_FOCUS_TASK_MS_WHEEL	0x00800000 //Does nothing, yet
#define WIF_FOCUS_TASK_BORDER	0x01000000
#define WIF_FOCUS_TASK_GRAB_SCROLL 0x02000000

#define WIG_DBL_CLICK		(WIF_FOCUS_TASK_MS_L_D|WIF_FOCUS_TASK_MS_R_D)
#define WIG_TASK_DFT		(WIF_FOCUS_TASK_MENU|WIG_DBL_CLICK|\
	0xFFFF-WIF_SELF_DOC-WIF_SELF_ODE)
#define WIG_NO_FOCUS_TASK_DFT	(WIG_TASK_DFT-WIF_SELF_BORDER\
	-WIF_SELF_MS_L-WIF_SELF_MS_R-WIG_DBL_CLICK)
#define WIG_USER_TASK_DFT	WIF_SELF_KEY_DESC

#define WIf_SELF_FOCUS		0
#define WIf_SELF_CTRLS		2
#define WIf_SELF_MS_L		3
#define WIf_SELF_MS_R		5
#define WIf_SELF_MS_WHEEL	7
#define WIf_SELF_BORDER		8
#define WIf_SELF_GRAB_SCROLL	9
#define WIf_SELF_DOC		10
#define WIf_SELF_ODE		11
#define WIf_SELF_KEY_DESC	12
#define WIf_FOCUS_TASK_MENU	17
#define WIf_FOCUS_TASK_CTRLS	18
#define WIf_FOCUS_TASK_MS_L	19
#define WIf_FOCUS_TASK_MS_L_D	20
#define WIf_FOCUS_TASK_MS_R	21
#define WIf_FOCUS_TASK_MS_R_D	22
#define WIf_FOCUS_TASK_MS_WHEEL	23
#define WIf_FOCUS_TASK_BORDER	24
#define WIf_FOCUS_TASK_GRAB_SCROLL 25

class CWinMgrTimingGlbls
{
  I64	last_total_jiffies,
	last_idle_pt_hits[MP_PROCESSORS_NUM],
	last_swap_cnter[MP_PROCESSORS_NUM];
  F64	last_calc_idle_time,calc_idle_delta_time;
  I64	calc_idle_cnt;
};

#define WINMGR_FPS	(30000.0/1001)
#define WINMGR_PERIOD	(1001/30000.0)

public class CWinMgrGlbls
{
  I64	updates;
  F64	ode_time,
	last_ode_time,
	fps,		//You can read but not write this. You have no control.
	ideal_refresh_tS,
	last_refresh_tS;
  CWinMgrTimingGlbls *t;
  Bool	show_menu,grab_scroll,grab_scroll_closed;
};

#help_index "AutoComplete"
#define ACf_INIT_IN_PROGRESS	0
#define AC_FILLINS_NUM 10
public class CAutoCompleteGlbls
{
  I64	num_words;
  CHashTable *hash_table;
  U8	*cur_word;
  I64	flags;
  CTask	*task;
  I64	partial_len,num_fillins,
	fillin_hits	[AC_FILLINS_NUM+1];
  CHashAC *fillin_matches[AC_FILLINS_NUM+1];
};

#help_index "AutoComplete/Dictionary"
#define ACD_WORD_FILENAME	"/Adam/AutoComplete/ACWords.DATA.Z"
#define ACD_DEF_FILENAME	"/Adam/AutoComplete/ACDefs.DATA"
#define ACD_DEF_FILENAME_Z	"/Adam/AutoComplete/ACDefs.DATA.Z"

#define ACD_H1			0
#define ACD_H1_END		1
#define ACD_DEF			2
#define ACD_DEF_END		3
#define ACD_PRONUNCIATION	4
#define ACD_PRONUNCIATION_END	5
#define ACD_POS			6
#define ACD_POS_END		7
#define ACD_EXTRA		8
#define ACD_EXTRA_END		9
#define ACD_BLK_SIZE		0x4000

#define ACD_END_CHAR		0x00
#define ACD_WORD_CHAR		0x01
#define ACD_DEF_CHAR		0x02
#define ACD_PRONUNCIATION_CHAR	0x03
#define ACD_POS_CHAR		0x04
#define ACD_EXTRA_CHAR		0x05

#define ACD_FILLINS_NUM 10
public class CAutoCompleteDictGlbls
{
  U8	*word_lst;
  I64	word_lst_size,num_words,num_fillins;
  U8	*fillins[ACD_FILLINS_NUM];
  Bool	has_words,has_defs;
};

#include "/Kernel/CompilerTypes.HH"

#help_index "Debugging/Unassemble"
class CUAsmGlbls
{
  CInst **table_16_32,**table_64;
  I64	table_16_32_entries,
	table_64_entries,
	ins64_arg_mask,
	signed_arg_mask,
	mem_arg_mask;
};

#help_index "Devices;PCI"
class CPCIDev
{
  CPCIDev *next,*last;
  U16	vendor,dev_id;
  U8	bus,dev,fun,pad,
	sub_code,base_code,pad[6],
	*vendor_str,*dev_id_str;
};

#help_index "Devices;File/System;PCI"
public class CATARep
{
  CATARep *next;
  I64	num,type,base0,base1,unit,irq;
};

//See $LK,"::/Doc/Credits.DD"$.
#define ATA_NOP			0x00
#define ATA_DEV_RST		0x08
#define ATA_PACKET		0xA0
#define ATA_READ_NATIVE_MAX	0xF8
#define ATA_READ_NATIVE_MAX_EXT	0x27
#define ATA_SET_MAX		0xF9
#define ATA_SET_MAX_EXT		0x37
#define ATA_READ_MULTI		0xC4
#define ATA_READ_MULTI_EXT	0x29
#define ATA_WRITE_MULTI		0xC5
#define ATA_WRITE_MULTI_EXT	0x39
#define ATA_ID_DEV		0xEC

#define ATAS_ERR	0x01
#define ATAS_DRQ	0x08
#define ATAS_DF		0x20
#define ATAS_DRDY	0x40
#define ATAS_BSY	0x80

#define ATAR0_DATA	0
#define ATAR0_FEAT	1
#define ATAR0_NSECT	2
#define ATAR0_SECT	3
#define ATAR0_LCYL	4
#define ATAR0_HCYL	5
#define ATAR0_SEL	6
#define ATAR0_STAT	7
#define ATAR0_CMD	7
#define ATAR1_CTRL	2

#help_index "File/FileNames"
#define FILEMASK_JIT	"*.HC*;*.HH*"
#define FILEMASK_AOT	"*.HC*;*.HH*;*.PRJ*"
#define FILEMASK_SRC	"*.HC*;*.HH*;*.IN*;*.PRJ*"
#define FILEMASK_DD	FILEMASK_SRC ";*.DD*"
#define FILEMASK_TXT	FILEMASK_DD ";*.TXT*"
#define FILEMASK_GR	"*.GR*"

#help_index "File/Low Level"
#define BLK_SIZE_BITS	9
#define BLK_SIZE	(1<<BLK_SIZE_BITS)
#define DVD_BLK_SIZE	(4*BLK_SIZE)
#define DVD_BOOT_LOADER_SIZE	DVD_BLK_SIZE*1
#define INVALID_CLUS (-1)

class CMBRPrt
{
  U8	active,	//0x80=active  0x00=inactive
	start_head;
  U16	start_cyl;
  U8	type,
	end_head;
  U16	end_cyl;
  U32	offset,	//Sects between MBR and first sect
	size;	//Sects in drv
};

class CMasterBoot
{
  U8	code[440];
  U32	media_id;
  U16	zero;
  CMBRPrt p[4];
  U16	signature; //AA55
};

class CRedSeaBoot
{
  U8	jump_and_nop[3],
	signature,reserved[4]; //MBR_PT_REDSEA=0x88. Distinguish from real FAT32
  I64	drv_offset,	//For CD/DVD image copy.
	sects,
	root_clus,
	bitmap_sects,
	unique_id;
  U8	code[462];
  U16	signature2;	//0xAA55
};

class CFAT32Boot
{
  U8	jump_and_nop[3],
	oem_name[8];
  U16	bytes_per_sect;
  U8	sects_per_clus;
  U16	reserved_sects;
  U8	copies_of_fat;
  U16	max_root_dir_entries,	//Not used
	old_sects_in_drv;	//Not used
  U8	media_desc;		//F64 for hard disk
  U16	old_sects_per_fat,	//Not used
	sects_per_track,
	num_heads;
  U32	hidden_sects,
	sects,
	sects_per_fat;
  U16	flags,
	version;
  U32	root_clus;
  U16	file_system_info_sect,
	backup_boot_sect;
  U8	reserved[12],
	log_drv_num,
	unused,
	ext_signature; //0x29
  U32	serial_num;
  U8	vol_name[11],
	fat_name[8],
	code[420];
  U16	signature;
};

class CFAT32FileInfoSect
{
  U32	signature1;
  U8	unknown[480];
  U32	signature2,
	free_clus,
	most_recently_alloced;
  U8	reserved[12];
  U32	signature3;
};

class CFAT32DirEntry
{
  U8	name[11],
	attr,
	NTres,
	CrtTimeTenth;
  U16	CrtTime,
	CrtDate,
	LstAccDate,
	clus_hi,
	WrtTime,
	WrtDate,
	clus_lo;
  U32	size;
};

class CFAT32DirEntryLong
{
  U8	ord;
  U16	name1[5];
  U8	attr,
	type,
	xsum;
  U16	name2[6],
	zero,
	name3[2];
};

#define FAT32_ENTRIES_PER_BLK	(BLK_SIZE/sizeof(CFAT32DirEntry))
#define FAT32_ENTRIES_BITS	Bsf(FAT32_ENTRIES_PER_BLK)

class CPalindromeU16
{
  U16	little,big;
};

class CPalindromeU32
{
  U32	little,big;
};

class CATAPITrack
{
  U16	track_info_len;
  U8	track_lo,
	session_lo,
	reserved;
  U16	misc1;
  U8	misc2;
  U32	track_start,
	next_writable,
	free_blks;
  union {
    U32 fixed_packet_size;
    U32 blocking_factor;
  };
  union {
    U32 track_size;
    U32 rzone_end;
  };
  U32	last_recorded;
  U8	track_hi,
	session_hi;
  U16	reserved;
  U32	read_compatibility,
	next_layer_jmp,
	last_layer_jmp;
};

//ISO9660
#define ISOT_BOOT_RECORD	0
#define ISOT_PRI_VOL_DESC	1
#define ISOT_SUPPLEMENTARY_DESC	2
#define ISOT_VOL_DRV_DESC	3
#define ISOT_TERMINATOR		255

class CISODirEntry
{
  U8 pad[2];
  CPalindromeU32 loc;
  U8 pad[24];
};

class CISOPriDesc
{
  U8	type,
	id[5],
	version,
	pad[73];
  CPalindromeU32 vol_space_size;
  U8	pad[32];
  CPalindromeU16 vol_set_size;
  CPalindromeU16 vol_seq_num;
  CPalindromeU16 log_block_size;
  U8	pad[20];
  CISODirEntry root_dir_record;
  U8	pad[128],
	publisher_id[128],
	pad[435],
	file_structure_version,
	pad[1166];
};

//Red Sea Attributes
//See $LK,"ST_FILE_ATTRS",A="MN:ST_FILE_ATTRS"$
#include "/Kernel/BlkDev/RedSeaAttr.HH"

#help_index "File/CD DVD"
//Media types for $LK,"DVDImageWrite",A="MN:DVDImageWrite"$()
#define MT_CD		1
#define MT_DVD		2

#help_index "File/Low Level;File/Program Routines"
//CDirEntry flags (Used by $LK,"FileMgr",A="MN:FileMgr"$())
#define CDIR_FILENAME_LEN	38 //Must include terminator zero
public class CDirEntry
{
  CDirEntry *next,*parent,*sub;
  U8	*full_name;
  I64	user_data,user_data2;

  U0	start;
  U16	attr;
  U8	name[CDIR_FILENAME_LEN];
  I64	clus,size;
  CDate datetime;
};
#define CDIR_SIZE (sizeof(CDirEntry)-offset(CDirEntry.start))

#help_index "File/Program Routines"
//File Util Flags
//See $LK,"ST_FILE_UTIL_FLAGS",A="MN:ST_FILE_UTIL_FLAGS"$
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
#define FUf_JUST_TXT		12
#define FUf_JUST_DD		13
#define FUf_JUST_SRC		14
#define FUf_JUST_AOT		15
#define FUf_JUST_JIT		16
#define FUf_JUST_GR		17
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
#define FUF_JUST_DIRS		0x0000400 //D
#define FUF_JUST_FILES		0x0000800 //F
#define FUF_JUST_TXT		0x0001000 //T
#define FUF_JUST_DD		0x0002000 //$$
#define FUF_JUST_SRC		0x0004000 //S
#define FUF_JUST_AOT		0x0008000 //A
#define FUF_JUST_JIT		0x0010000 //J
#define FUF_JUST_GR		0x0020000 //G
#define FUF_Z_OR_NOT_Z		0x0040000 //Z
#define FUF_CLUS_ORDER	0x0080000 //O Move disk head one direction
#define FUF_SCAN_PARENTS	0x0100000 //P
#define FUF_FLATTEN_TREE	0x0200000 //f
#define FUF_WHOLE_LABELS	0x0400000 //l
#define FUF_WHOLE_LABELS_BEFORE	0x0800000 //lb
#define FUF_WHOLE_LABELS_AFTER	0x1000000 //la

#define FUG_FILES_FIND	(FUF_RECURSE|FUF_SINGLE|FUF_CLUS_ORDER|\
  FUF_JUST_DIRS|FUF_JUST_FILES|FUF_JUST_TXT|FUF_JUST_DD|\
  FUF_JUST_SRC|FUF_JUST_AOT|FUF_JUST_JIT|FUF_JUST_GR|FUF_FLATTEN_TREE)
#define FUG_FILE_FIND	(FUF_JUST_DIRS|FUF_JUST_FILES|FUF_Z_OR_NOT_Z|\
  FUF_SCAN_PARENTS)

#help_index "File/Low Level"
//See $LK,"ST_BLKDEV_TYPES",A="MN:ST_BLKDEV_TYPES"$
#define BDT_NULL		0
#define BDT_RAM			1
#define BDT_ATA			2
#define BDT_ISO_FILE_READ	3
#define BDT_ISO_FILE_WRITE	4
#define BDT_ATAPI		5
#define BDT_TYPES_NUM		6

#define BDF_REMOVABLE		0x001
#define BDF_INITIALIZED		0x002
#define BDF_READ_ONLY		0x004
#define BDF_READ_ONLY_OVERRIDE	0x008
#define BDF_LAST_WAS_WRITE	0x010
#define BDF_READ_CACHE		0x020
#define BDF_FMT			0x040
#define BDF_INIT_IN_PROGRESS	0x080
#define BDF_EXT_SIZE		0x100

#define BDf_REMOVABLE		0
#define BDf_INITIALIZED		1
#define BDf_READ_ONLY		2
#define BDf_READ_ONLY_OVERRIDE	3
#define BDf_LAST_WAS_WRITE	4
#define BDf_READ_CACHE		5
#define BDf_FMT			6
#define BDf_INIT_IN_PROGRESS	7
#define BDf_EXT_SIZE		8

//locked flags
#define BDlf_LOCKED		0

#define BLKDEVS_NUM		26
#define BD_SIGNATURE_VAL	'BDSV'
public class CBlkDev
{
  CBlkDev *lock_fwding; //If two blkdevs on same controller, use just one lock
  I64	locked_flags;
  U32	bd_signature,
	type,flags;
  U8	first_drv_let,unit,pad[2];
  U32	base0,base1,
	blk_size;
  I64	drv_offset,init_root_dir_blks,
	max_blk;
  U16	*dev_id_record;
  U8	*RAM_dsk,
	*file_dsk_name;
  CFile *file_dsk;
  CTask *owning_task;
  F64	last_time;
  U32	max_reads,max_writes;
};

//Drive locked_flags
#define DVlf_LOCKED	0

//See $LK,"ST_DRV_TYPES",A="MN:ST_DRV_TYPES"$
#define FSt_NULL	0
#define FSt_REDSEA	1 //Supported
#define FSt_FAT32	2 //Supported except for short names, to some degree
#define FSt_ISO9660	3 //Not Supported
#define FSt_NTFS	4 //Not Supported
#define FSt_UNKNOWN	5
#define FSt_TYPES_NUM	6
#define FSG_TYPE_MASK	0x7FFF
//File system type flags
#define FStf_DISABLE	15

#define MBR_PT_FAT12	0x01
#define MBR_PT_FAT32a	0x0B
#define MBR_PT_FAT32b	0x0C
#define MBR_PT_FAT32c	0x1B
#define MBR_PT_FAT32d	0x1C
#define MBR_PT_FAT32e	0x8B
#define MBR_PT_FAT32f	0x8C
#define MBR_PT_NTFS	0x07
#define MBR_PT_REDSEA	0x88

class CFreeLst
{
  CFreeLst *next,*last;
  I64	start,size;
};

#define DRVS_NUM		26

#define DRV_SIGNATURE_VAL	'DVSV'
public class CDrv
{
//Don't access ->drv_let directly in case a drive has been remapped.
  //Use $LK,"Drv2Let",A="MN:Drv2Let"$().
  I64	locked_flags;
  U32	dv_signature;
  U8	drv_let,pad;
  U16	fs_type;
  I64	drv_offset,
	size,
	prt_num,
	file_system_info_sect,
	fat1,fat2,
	root_clus,
	data_area,
	spc; //sectors per clus
  CDate fat32_local_time_offset;
  CTask *owning_task;
  CBlkDev *bd;

  CFAT32FileInfoSect *fis;
  I64	fat_blk_dirty,
	cur_fat_blk_num;
  U32	*cur_fat_blk;
  CFreeLst *next_free,*last_free;
};

#define DSK_CACHE_HASH_SIZE	0x2000

class CCacheBlk
{
  CCacheBlk *next_lru,*last_lru;
  CCacheBlk *next_hash,*last_hash;
  CDrv	*dv;
  I64	blk;
  U8	body[BLK_SIZE];
};

#help_index "File/System"
#define DFT_ISO_FILENAME	"::/Tmp/CDDVD.ISO"
#define DFT_ISO_C_FILENAME	"::/Tmp/CDDVD.ISO.C"

public class CBlkDevGlbls
{
  CBlkDev *blkdevs;
  U8	*dft_iso_filename;	//$TX,"\"::/Tmp/CDDVD.ISO\"",D="DFT_ISO_FILENAME"$
  U8	*dft_iso_c_filename;	//$TX,"\"::/Tmp/CDDVD.ISO.C\"",D="DFT_ISO_C_FILENAME"$
  U8	*tmp_filename;
  U8	*home_dir;
  CCacheBlk *cache_base,*cache_ctrl,**cache_hash_table;
  I64	cache_size,read_cnt,write_cnt;
  CDrv	*drvs,*let_to_drv[32];
  I64	mount_ide_auto_cnt,
	ins_base0,ins_base1;	//Install cd/dvd controller.
  U8	boot_drv_let,first_hd_drv_let,first_dvd_drv_let;
  Bool	dvd_boot_is_good,ins_unit,pad[3];
};

#help_index "File/Internal"
public class CDirContext
{
  CDrv	*old_dv,*dv;
  U8	*old_dir,*mask;
};

#help_index "File/CFile"
#define FFB_NEXT_BLK		I64_MAX

#define FF_WRITE		1
#define FF_NEW_FILE		2
#define FF_BUF_DIRTY		4
#define FF_NEEDS_WRITE		8
#define FF_CONTIGUOUS		16
#define FF_USE_OLD_DATETIME	32

public class CFile //See $LK,"::/Demo/Dsk/DataBase.HC"$.
{
  I64	flags;
  CDirEntry de;
  CDrv	*dv;
  I64	fblk_num,clus,file_clus_num,max_blk;
  U8	*clus_buf;
};

#help_index "Memory/Heap"
#define _CFG_HEAP_DBG FALSE

#if _CFG_HEAP_DBG
#include "/Kernel/MemoryAllocDebugTypes.HH"
#else
#include "/Kernel/MemoryAllocTypes.HH"
#endif
#help_index "Memory/BlkPool"
#help_file "::/Doc/Pags"
#include "/Kernel/MemoryTypes.HH"

#help_index "Devices;Memory/Page Tables"
public class CDevGlbls
{
  I64	*idt;
  U8	*mem64_ptr;
  U8	*uncached_alias; //Alias of lowest 4Gig.
  U8	mp_apic_ids[MP_PROCESSORS_NUM];
  CMemRange mem32_head;
  CPCIDev pci_head;
};

#help_index "Graphics/Color;Graphics/Device Contexts"
//Raster operations
#define ROPB_EQU			0x00
#define ROPB_XOR			0x01
#define ROPB_COLLISION			0x02
#define ROPB_MONO			0x03
#define ROPBF_HALF_RANGE_COLOR		0x10
#define ROPBF_TWO_SIDED			0x20
#define ROPBF_DITHER			0x40
#define ROPBF_PROBABILITY_DITHER	0x80

#define ROP_EQU				(ROPB_EQU<<8)
#define ROP_XOR				(ROPB_XOR<<8)
#define ROP_COLLISION			(ROPB_COLLISION<<8)
#define ROP_MONO			(ROPB_MONO<<8)

//These are just for $LK,"ROPF_PROBABILITY_DITHER",A="MN:ROPF_PROBABILITY_DITHER"$
//See $LK,"DCLighting",A="MN:DCLighting"$().
#define ROPF_HALF_RANGE_COLOR		0x1000
#define ROPF_TWO_SIDED			0x2000

//These always go in the c1.rop of a CColorROPU32
#define ROPF_DITHER			0x40000000
#define ROPF_PROBABILITY_DITHER		0x80000000

#help_index "Graphics/Color"
#define TRANSPARENT		0xFF
#define BLACK			0
#define BLUE			1
#define GREEN			2
#define CYAN			3
#define RED			4
#define PURPLE			5
#define BROWN			6
#define LTGRAY			7
#define DKGRAY			8
#define LTBLUE			9
#define LTGREEN			10
#define LTCYAN			11
#define LTRED			12
#define LTPURPLE		13
#define YELLOW			14
#define WHITE			15

#define COLORS_NUM		16
#define COLOR_INVALID		16
#define COLOR_MONO		0xFF

public U16 class CColorROPU16 //Don't use this, use CColorROPU32
{
  U8	color,rop;
};
public U32 class CColorROPU32
{
  CColorROPU16 c0,c1;
};
#define COLORROP_COLORS_MASK	0x00FF00FF
#define COLORROP_NO_ROP0_MASK	0xFFFF00FF
#define COLORROP_BITS		16
public U32 class CBGR24
{
  U8	b,g,r,pad;
};
public I64 class CBGR48
{
  U16	b,g,r,pad;
};

#help_index "Keyboard Devices;Char/Input;StdIn"
#define KBD_PORT	0x60
#define KBD_CTRL	0x64
public class CKbdStateGlbls
{
  I64	scan_code,	//See $LK,"scan codes",A="FI:::/Doc/CharOverview.DD"$
	last_down_scan_code,
	cnt,		//Count of keys pressed since boot.
	timestamp,	//Output: GetTSC when event.
	new_key_timestamp; //Output: GetTSC when new key event.
  CFifoU8 *fifo,*fifo2; //Private
  CFifoI64 *scan_code_fifo;

  //BitTest, $LK,"Bt",A="MN:Bt"$(), with a merged scan code.
  //(Left and right shift merged, for example.)
  U32	down_bitmap[8],
//BitTest, $LK,"Bt",A="MN:Bt"$(), with an unmerged scan code.
	down_bitmap2[8];

  Bool	rst,		//Private: Reset KbdMs
	irqs_working;	//Private
};

#help_index "Mouse"
public class CMsHardStateGlbls
{
  CD3I64 pos,		//Position in pixels
	prescale;
  CD3	scale;
  F64	speed;		//Output: How fast the user is moving it.
  I64	timestamp,	//Output: GetTSC when event.
	install_attempts, //Private
	pkt_size;	//Private
  CFifoU8 *fifo,*fifo2; //Private
  Bool	bttns[5],
	has_wheel,
	has_ext_bttns,
	evt,		//Private
	installed,	//Private
	install_in_progress, //Private
	irqs_working;	//Private
};

public class CMsStateGlbls
{
  CD3I64 pos,		//Position in pixels
	pos_text,	//Position in text rows,cols
	presnap,
	offset;
  CD3	scale;
  F64	speed;		//Output: How fast the user is moving it.
  I64	timestamp;	//Output: GetTSC when event.
  F64	dbl_time,	//Input: Time threshold for calling it a double click.
	left_dbl_time,	//Private
	right_dbl_time;	//Private
  Bool	lb,		//Left Bttn
	rb,		//Right Bttn
	show,
	has_wheel,
	left_dbl,	//Private
	left_down_sent, //Private
	right_dbl,	//Private
	right_down_sent;//Private
};

public class CGridGlbls
{
  Bool	snap	format "$$CB,\"Snap Grid\"$$\n",
	show	format "$$CB,\"Show Grid\"$$\n",
	coord	format "$$CB,\"Show Coordinates\"$$\n";
  U8	pad[5];
  F64	x	format "$$DA-TRM,A=\"X Spacing:%6.3f\"$$\n",
	y	format "$$DA-TRM,A=\"Y Spacing:%6.3f\"$$\n",
	z	format "$$DA-TRM,A=\"Z Spacing:%6.3f\"$$\n",
	x_offset format "$$DA-TRM,A=\"X Offset :%6.3f\"$$\n",
	y_offset format "$$DA-TRM,A=\"Y Offset :%6.3f\"$$\n",
	z_offset format "$$DA-TRM,A=\"Z Offset :%6.3f\"$$\n",
	x_speed	format "$$DA-TRM,A=\"X Speed  :%6.3f\"$$\n",
	y_speed	format "$$DA-TRM,A=\"Y Speed  :%6.3f\"$$\n",
	z_speed	format "$$DA-TRM,A=\"Z Speed  :%6.3f\"$$\n";
};

#help_index "Ctrls"
#define CTRLT_GENERIC		0
#define CTRLT_WIN_HSCROLL	1 //unique
#define CTRLT_WIN_VSCROLL	2 //unique
#define CTRLT_VIEWING_ANGLES	3 //unique

#define CTRLF_SHOW		1
#define CTRLF_BORDER		2
#define CTRLF_CAPTURE_LEFT_MS	4
#define CTRLF_CAPTURE_RIGHT_MS	8
#define CTRLF_CLICKED		16

#define WSSf_SET_TO_POS		0

#include "/Kernel/WindowScrollTypes.HH"

public class CViewAngles
{
  I64	sx,sy,sz;
  F64	ax,ay,az;
  CColorROPU32 cx,cy,cz,cbd,cbg,cfg;
};

public class CCtrl
{
  CCtrl *next,*last;
  CTask *win_task;
  I64	type,flags;

  //win pix coordinates
  I64	left,right,top,bottom;

  //scrn pix coordinates (derived)
  I64	scrn_left,scrn_right,scrn_top,scrn_bottom;

  U8	*state;

  //called on resize
  U0	(*update_derived_vals)(CCtrl *c);
  U0	(*draw_it)(CDC *dc,CCtrl *c);

  Bool	(*inside_ctrl)(CCtrl *c,I64 x,I64 y); //For nonbox shapes
  U0	(*left_click)(CCtrl *c,I64 x,I64 y,Bool down);
  U0	(*right_click)(CCtrl *c,I64 x,I64 y,Bool down);
  U0	(*wheel_chg)(CCtrl *c,I64 delta);
};

#help_index "Menus"
public class CMenuEntry
{
  CMenuEntry *next;
  CMenuEntry *sub;
  U8	name[32];
  I64	msg_code,arg1,arg2;
  Bool	checked,dir,pad[6];
};

public class CMenu
{
  CMenu *next;
  CMenuEntry *sub;
  CTask *task;
  I64	flags;
  U8	attr,pad[7];
};

#help_index "Task"
class CBpt
{
  CBpt	*next;
  U8	*addr,
	val,pad[7];
};

class CExcept
{
  CExcept *next,*last;
  I64	hndlr_catch,hndlr_untry,
	rsp,rbp,rflags,rsi,rdi,r10,r11,r12,r13,r14,r15;
};

class CFPU
{
  U8	body[512];
};

#help_index "Job/Exe;Task/Job/Exe"
#define JOBf_WAKE_MASTER	0
#define JOBf_FOCUS_MASTER	1
#define JOBf_EXIT_ON_COMPLETE	2
#define JOBf_DONT_FILTER	3
#define JOBf_HIGHEST_PRIORITY	4
//MP flags
#define JOBf_DONE		5
#define JOBf_DISPATCHED		6
#define JOBf_FREE_ON_COMPLETE	7
#define JOBf_ADD_TO_QUE		8

#define JOBT_TEXT_INPUT		0 //$LK,"TaskText",A="MN:TaskText"$()	Feed StdIn
#define JOBT_MSG		1 //$LK,"TaskMsg",A="MN:TaskMsg"$()	Post msg
#define JOBT_EXE_STR		2 //$LK,"TaskExe",A="MN:TaskExe"$()	Compile & execute src code text
//MP cmds
#define JOBT_CALL		3 //$LK,"JobQue",A="MN:JobQue"$()	Tell MP to call function
#define JOBT_SPAWN_TASK		4 //$LK,"Spawn",A="MN:Spawn"$()	Tell MP to spawn task

class CJob
{
  CJob *next,*last;
  CJobCtrl *ctrl;
  I64	job_code,flags,msg_code;

  I64	(*addr)(U8 *fun_arg);
  U8	*fun_arg;

  U8	*aux_str;
  I64	aux1,aux2, //Sometimes called arg1 and arg2. (Windows msg param1 param2)
	res;

  CTask	*spawned_task,
	*master_task;
};

#include "/Kernel/JobCtrlTypes.HH"

#help_index "Messages"
//See $LK,"::/Demo/MsgLoop.HC"$
#define MSG_NULL		0
#define MSG_CMD			1
#define MSG_KEY_DOWN		2  //($LK,"ASCII",A="MN:CH_CTRLA"$,$LK,"scan code",A="FI:::/Doc/CharOverview.DD"$) Press <CTRL-SHIFT-L>
#define MSG_KEY_UP		3  //($LK,"ASCII",A="MN:CH_CTRLA"$,$LK,"scan code",A="FI:::/Doc/CharOverview.DD"$) Press <CTRL-SHIFT-L>
#define MSG_MS_MOVE		4  //(x,y)
#define MSG_MS_L_DOWN		5  //(x,y)
#define MSG_MS_L_UP		6  //(x,y)
#define MSG_MS_L_D_DOWN 	7  //(x,y)
#define MSG_MS_L_D_UP		8  //(x,y)
#define MSG_MS_R_DOWN		9  //(x,y)
#define MSG_MS_R_UP		10 //(x,y)
#define MSG_MS_R_D_DOWN 	11 //(x,y)
#define MSG_MS_R_D_UP		12 //(x,y)

//Fake messages used to send both an up and down.
#define MSG_KEY_DOWN_UP		-2  //Down & UP
#define MSG_MS_L_DOWN_UP	-5  //Down & Up
#define MSG_MS_L_D_DOWN_UP	-7  //Down & Up
#define MSG_MS_R_DOWN_UP	-9  //Down & Up
#define MSG_MS_R_D_DOWN_UP	-11 //Down & Up

#help_index "Task/Settings"
#define TSF_SAME_SONG	1
public class CTaskSettings
{
  CTaskSettings *next;
  U8	*cur_dir;
  I64	left,right,top,bottom;
  U0	(*draw_it)(CTask *task,CDC *dc);
  U0	(*task_end_cb)();
  CTask *song_task,*animate_task;
  I64	scroll_x,scroll_y,scroll_z;
  CBGR48 palette[COLORS_NUM];
  U32	win_inhibit;
  U8	text_attr,title_src,
	border_attr,border_src,
	task_title[STR_LEN];
  Bool	border,hide_cursor,highlight_cursor,scroll,autocomplete,pad[3];
#assert !($$&7)
};

#help_index "Task"
//CTask.border_src
#define BDS_CONST		0
#define BDS_CUR_DRV		1
#define BDS_ED_FILENAME_DRV	2

//CTask.title_src
#define TTS_CONST		0
#define TTS_LOCKED_CONST	1 //This is not strictly enforced
#define TTS_TASK_NAME		2
#define TTS_ED_FILENAME		3
#define TTS_CUR_LEX		4

#include "/Kernel/TaskFlags.HH"

//CTask.display_flags
#define DISPLAYf_SHOW			0
#define DISPLAYf_NOT_RAW		1
#define DISPLAYf_SILENT			2
#define DISPLAYf_NO_BORDER		3
#define DISPLAYf_WIN_ON_TOP		4
#define DISPLAYf_CHILDREN_NOT_ON_TOP	5

#include "/Kernel/TaskTypes.HH"

class CTSS
{
  U32	res1;
  I64	rsp0,rsp1,rsp2,res2,
	ist1,ist2,ist3,ist4,ist5,ist6,ist7,res3;
  U16	res4,io_map_offset;
  U8	io_map[0x10000/8];
  I64	*st0,*st1,*st2;
  U16	tr,tr_ring3;
};

#define ans	(Fs->answer)
#define ansf	(Fs->answer(F64))

#define _RAX Fs->rax
#define _RBX Fs->rbx
#define _RCX Fs->rcx
#define _RDX Fs->rdx
#define _RSI Fs->rsi
#define _RDI Fs->rdi
#define _RBP Fs->rbp
#define _RSP Fs->rsp
#define _RIP Fs->rip
#define _R8  Fs->r8
#define _R9  Fs->r9
#define _R10 Fs->r10
#define _R11 Fs->r11
#define _R12 Fs->r12
#define _R13 Fs->r13
#define _R14 Fs->r14
#define _R15 Fs->r15

#help_index "MultiCore"
#define CPUf_RAN_A_TASK		0
#define CPUf_DYING_TASK_QUE	1

#include "/Kernel/CpuTypes.HH"

#help_index "Memory/Page Tables"
#define MEM_MIN_MEG		512 //512 Meg minimum.

#define SYS_FIXED_AREA		0x100000
#define SYS_16MEG_AREA_LIMIT	0x1000000
public class CSysFixedArea
{
  CFPU	init_fpu_mmx;
  CCPU	boot_cpu;
  CTask	adam;
  CBlkPool sys_code_bp;
  CHeapCtrl adam_hc;
  $$=($$+0x1000-1)&-0x1000;
};

#include "/Kernel/CharCodes.HH"

#define ST_ERR_ST   "$$LTRED$$$$BK,1$$ERROR:$$FG$$$$BK,0$$ "
#define ST_WARN_ST  "$$RED$$$$BK,1$$WARNING:$$FG$$$$BK,0$$ "

//Scan code flags
#define SCf_E0_PREFIX	7
#define SCf_KEY_UP	8
#define SCf_SHIFT	9
#define SCf_CTRL	10
#define SCf_ALT 	11
#define SCf_CAPS	12
#define SCf_NUM 	13
#define SCf_SCROLL	14
#define SCf_NEW_KEY	15
#define SCf_MS_L_DOWN	16
#define SCf_MS_R_DOWN	17
#define SCf_DELETE	18
#define SCf_INS		19
#define SCf_NO_SHIFT	30
#define SCf_KEY_DESC	31
#define SCF_E0_PREFIX	(1<<SCf_E0_PREFIX)
#define SCF_KEY_UP	(1<<SCf_KEY_UP)
#define SCF_SHIFT	(1<<SCf_SHIFT)
#define SCF_CTRL	(1<<SCf_CTRL)
#define SCF_ALT		(1<<SCf_ALT)
#define SCF_CAPS	(1<<SCf_CAPS)
#define SCF_NUM		(1<<SCf_NUM)
#define SCF_SCROLL	(1<<SCf_SCROLL)
#define SCF_NEW_KEY	(1<<SCf_NEW_KEY)
#define SCF_MS_L_DOWN	(1<<SCf_MS_L_DOWN)
#define SCF_MS_R_DOWN	(1<<SCf_MS_R_DOWN)
#define SCF_DELETE	(1<<SCf_DELETE)
#define SCF_INS 	(1<<SCf_INS)
#define SCF_NO_SHIFT	(1<<SCf_NO_SHIFT)
#define SCF_KEY_DESC	(1<<SCf_KEY_DESC)

#include "/Kernel/ScanCodes.HH"

#help_index "Char;Debugging/Raw Output;TextBase Layer/Char"
//text.raw_flags
#define RWF_IN_DOLLAR	1
#define RWF_LAST_DOLLAR	2
#define RWF_SHOW_DOLLAR	4
#define RWF_SCROLL	8

public class CTextGlbls
{
  I64	raw_col,raw_flags;
  U8	*raw_scrn_image;
  I64	rows,cols;		//Use TEXT_ROWS,TEXT_COLS
  U64	*font,*aux_font;
  U8	*vga_alias,*vga_text_alias;
  U8	border_chars[16];
};

#define FONT_WIDTH	8
#define FONT_HEIGHT	8

#help_index "Graphics"
#define GR_WIDTH	640
#define GR_HEIGHT	480

//z-vals less than zero are in front of scrn and not drawn.
//we want to shift all Z-vals into a drawable range.
//GR_Z_ALL is set to half of the Z-range which is an I32.
#define GR_Z_ALL	(I32_MAX/2)

#help_index "Graphics/Device Contexts"
//Low 8 bits reserved for flags that go into saved bitmaps
#define DCF_COMPRESSED		1
#define DCF_PALETTE		2
#define DCF_NO_TRANSPARENTS	4 //Can be used to optimized $LK,"GrBlot",A="MN:GrBlot"$().

#define DCF_TRANSFORMATION	0x100

//See $LK,"DCSymmetrySet",A="MN:DCSymmetrySet"$() or $LK,"DCSymmetry3Set",A="MN:DCSymmetry3Set"$()
#define DCF_SYMMETRY		0x200

//Must be used with DCF_SYMMETRY set also.
//See $LK,"::/Demo/Games/BigGuns.HC"$
#define DCF_JUST_MIRROR		0x400

#define DCF_LOCATE_NEAREST	0x800
#define DCF_DONT_DRAW		0x1000
#define DCF_ALIAS		0x2000
#define DCF_SCRN_BITMAP		0x4000
#define DCF_FILL_NOT_COLOR	0x8000
#define DCF_RECORD_EXTENTS	0x10000
#define DCF_ON_TOP		0x20000

//$LK,"DCSave",A="MN:DCSave"$() flags.
#define DCSF_COMPRESSED		1
#define DCSF_PALETTE_GET	2

#define DCS_SIGNATURE_VAL	'DvCS'

class CGrSym
{
  I32	sx,sy,sz,pad;
//Normal of symmetry plane
  I64	snx,sny,snz;
};

public class CDC
{
  U0	start;
  CDate cdt;
  I32	x0,y0,
	width,width_internal,
	height,
	flags;
  U0	end;
  CBGR48 palette[COLORS_NUM];

  //public (Change directly)
  CColorROPU32 color,
	bkcolor, //Set for use with $LK,"ROP_COLLISION",A="MN:ROP_COLLISION"$
	color2; //Internally used for $LK,"GrFloodFill",A="MN:GrFloodFill"$()
  CD3I32 ls; //Light source (should be normalized to 65536).

  //dither_probability_u16 is basically a U16.
  //It is activated by $LK,"ROPF_PROBABILITY_DITHER",A="MN:ROPF_PROBABILITY_DITHER"$.
  //0x0000 =100% color.c0
  //0x8000 =50%  color.c0   50% color.c1
  //0x10000=100% color.c1
  //See $LK,"::/Demo/Graphics/SunMoon.HC"$ and	$LK,"::/Demo/Graphics/Shading.HC"$.
  U64 dither_probability_u16;

  CDC *brush;

  //Set with $LK,"DCMat4x4Set",A="MN:DCMat4x4Set"$().  $LK,"Free",A="MN:Free"$() before setting.
  I64	*r, //rotation matrix of quads decimal in lo
	r_norm; //shifted 32 bits.  Used for scaling thick

  //public (Change directly)
  I32	x,y,z,
	thick;

  //Can be changed from the default $LK,"DCTransform",A="MN:DCTransform"$()
  U0	(*transform)(CDC *dc,I64 *x,I64 *y,I64 *z);

  //Can be changed from the default $LK,"DCLighting",A="MN:DCLighting"$()
  U0	(*lighting)(CDC *dc,CD3I32 *p1,CD3I32 *p2,
	CD3I32 *p3,CColorROPU32 color);

  //Set by $LK,"DCSymmetrySet",A="MN:DCSymmetrySet"$() or $LK,"DCSymmetry3Set",A="MN:DCSymmetry3Set"$()
  CGrSym sym;

  I32	cur_x,cur_y,cur_z,pad;
  I64	collision_cnt;

  I64	nearest_dist,
	min_x,max_x,min_y,max_y; //Set by $LK,"DCF_RECORD_EXTENTS",A="MN:DCF_RECORD_EXTENTS"$ (scrn coordinates)

  U32	dc_signature,pad;
  CTask	*mem_task,*win_task;
  CDC	*alias;
  U8	*body;

  //Set by $LK,"DCDepthBufAlloc",A="MN:DCDepthBufAlloc"$()
  I32	*depth_buf;
  I64	db_z; //private
#assert !($$&7)
};

#help_index "Devices"
//VGA Memory
#define VGAM_GRAPHICS	0xA0000
#define VGAM_TEXT	0xB8000

//VGA I/O ports
#define VGAP_ATTR_INDEX		0x03C0
#define VGAP_ATTR_DATA_WRITE	0x03C0 //alias
#define VGAP_ATTR_DATA_READ	0x03C1
#define VGAP_MISC_OUTPUT	0x03C2
#define VGAP_IDX		0x03C4
#define VGAP_DATA		0x03C5
#define VGAP_PALETTE_MASK	0x03C6
#define VGAP_REG_READ		0x03C7
#define VGAP_REG_WRITE		0x03C8
#define VGAP_PALETTE_DATA	0x03C9
#define VGAP_CRTC_INDEX		0x03D4
#define VGAP_CRTC_DATA		0x03D5
#define VGAP_INPUT_STAT		0x03DA

//VGA Registers
#define VGAR_MAP_MASK		0x02

#help_index "Compression/Piece by Piece"
#include "/Kernel/Arc.HH"

#define "Char/Input;StdIn"
//GetStr flags
#define GSF_SHIFT_ESC_EXIT	1 //This kills task on <SHIFT-ESC>
#define GSF_WITH_NEW_LINE	2

#define "Char/Operations"
//Flags for StrUtil and MStrUtil
#define SUF_REM_CTRL_CHARS	0x001
#define SUF_REM_LEADING		0x002
#define SUF_REM_TRAILING	0x004
#define SUF_REM_SPACES		0x008
#define SUF_SINGLE_SPACE	0x010
#define SUF_TO_UPPER		0x020
#define SUF_TO_LOWER		0x040
#define SUF_S2T			0x080
#define SUF_T2S			0x100 // Only works with MStrUtil
#define SUF_SCALE_INDENT	0x200
#define SUF_SAFE_DOLLAR		0x400

//Flags for StrFind
#define SFF_IGNORE_CASE		1
#define SFF_WHOLE_LABELS_BEFORE	2
#define SFF_WHOLE_LABELS_AFTER	4
#define SFG_WHOLE_LABELS	(SFF_WHOLE_LABELS_BEFORE|SFF_WHOLE_LABELS_AFTER)

//Flags for LstMatch
#define LMF_IGNORE_CASE		1
#define LMF_EXACT		2

#help_index "Keyboard Devices/System"
#define KDF_HAS_DESCS	1
class CKeyDevEntry
{
  CKeyDevEntry *next,*last;
  I64	priority,flags;
  Bool	(*put_key)(I64 ch,I64 sc);
  Bool	(*put_s)(U8 *st);
};

class CKeyDevGlbls
{
  CKeyDevEntry put_key_head;
  U0	(**fp_ctrl_alt_cbs)(I64 sc);
  I64	ctrl_alt_in_irq_flags,
	**ctrl_alt_ret_addr; //addr of ret addr on stack in kbd irq
  U8	**ctrl_alt_no_shift_descs,**ctrl_alt_shift_descs,
	desc[STR_LEN],
	*hndlr;
};

#help_index "Snd"
#help_index "ScrnCast;Snd/AU Files"
public class CAUData
{//Fmt of AU files
  CDate	cdt;
  I8	ona;
};

class CSndData
{//Fmt recorded in mem
  CSndData *next,*last;
  F64	tS;
  I8	ona;
};

public class CScrnCastGlbls
{
  CSndData snd_head;
  CDate	t0_now;
  F64	t0_tS;
  U8	*print_fmt;
  CDC	*dc,*dc2_alias;
  Bool	record,just_audio;
  I8	ona;
};

#help_index "Debugging/FunSeg"
#define FUN_SEG_CACHE_SIZE	256
class CFunSegCache
{
  I64	base,limit;
  F64	time_stamp;
  U8	str[1]; //FUN_SEG_CACHE_STR_LEN
$$=64;
};
#define FUN_SEG_CACHE_STR_LEN	(sizeof(CFunSegCache)-offset(CFunSegCache.str))

#help_index "Debugging"
class CMPCrash
{
  I64	cpu_num;
  CTask *task;
  I64	rip;
  U8	*msg;
  I64	msg_num;
};

public class CDbgGlbls
{
  CTask *focus_task;
  U8	*msg;
  I64	msg_num;
  CMPCrash *mp_crash;
  U8	*int_fault_code,
	*fix_file_line;
  CFunSegCache *fun_seg_cache;
  I64	fun_seg_cache_index;
  Bool	panic;
};

#help_index "Boot"
//Boot related
#define BOOT_RAM_BASE		0x07C00
#define BOOT_RAM_LIMIT		0x97000
#define BOOT_STK_SIZE		BLK_SIZE

#define BOOT_SRC_NULL		0
#define BOOT_SRC_ROM		1
#define BOOT_SRC_RAM		2
#define BOOT_SRC_HARDDRV	3
#define BOOT_SRC_DVD		4

// $LK,"In",A="MN:In"$("") StdIn for call to $LK,"BootHDIns",A="MN:BootHDIns"$().
#define STD_DISTRO_DVD_CFG	"TB\nScale2Mem(2048,0x40000)\nT \n\n\n\n"

#help_index "Registry"
//Registry sys_msg_flags. $LK,"RegOneTimePopUp",A="MN:RegOneTimePopUp"$()
#define ARf_FLOODFILL			0
#define ARf_CSPRITE_INS_CLIP		1
#define ARf_PLANAR_SYMMETRY		2
#define ARf_PSALMODY_JUKEBOX		3
#define ARf_MESH_ED			4
#define ARf_CSPRITE_PTS_RECTANGLES	5
#define ARf_MANAGE_SLIDER		6

#help_index "Misc/Progress Bars"
#define PROGRESS_BARS_NUM	4
#define PROGRESS_DESC_LEN	(64-8-8)
class CProgress
{
  I64	val,max;
  F64	t0,tf;
  U8	desc[PROGRESS_DESC_LEN];
};

#help_index "Char/Operations"
#define PRTF_PAD_ZERO		0x001
#define PRTF_LEFT_JUSTIFY	0x002
#define PRTF_TRUNCATE		0x004
#define PRTF_COMMA		0x008
#define PRTF_DOLLAR		0x010
#define PRTF_SLASH		0x020
#define PRTF_QUESTION		0x040
#define PRTF_AUX_FMT_NUM	0x080
#define PRTF_DECIMAL		0x100
#define PRTF_NEG		0x200
#define PRTF_NEG_E		0x400
#define PRTF_NEG_AUX_FMT_NUM	0x800

#help_index "Misc/Host"
//Host Operating System
#define OS_OTHER	0
#define OS_NATIVE	1
#define OS_LINUX	2
#define OS_WINDOWS	3
//Virtual Machine
#define VM_OTHER	0
#define VM_NATIVE	1
#define VM_VMWARE	2
#define VM_QEMU		3
#define VM_VIRTUALBOX	4

#help_index "Registry/Install Registration"
public class CInsReg
{
  Bool	registered;
  I64	host_os		format "$$PURPLE$$Install Registration$$FG$$\n\n"
			"Host OS:$$LS,D=\"ST_HOST_OSES\"$$\n";
  I64	host_vm		format "Host VM:$$LS,D=\"ST_HOST_VMS\"$$\n";
  U8	initials[8]	format "$$DA-P,A=\"Your Initials:%s\"$$\n";
  I64	machine_num	format
			"$$DA-TRM,A=\"This Machine Num (Choose Any):%d\"$$\n";
};

#help_index ""
