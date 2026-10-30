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
#include "/Kernel/MathConstants.HH"
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

#include "/Kernel/GeometryTypes.HH"

#help_index "Data Types/Queue Vector"
#define QUE_VECT_U8_CNT		512
public class CQueVectU8
{
  CQueVectU8	*next,*last;
  I64	total_cnt,node_cnt,min_idx;
  U8	body[QUE_VECT_U8_CNT];
};

#include "/Kernel/FifoTypes.HH"

#include "/Kernel/DateTypes.HH"

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

#include "/Kernel/RunLevelTypes.HH"

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
#include "/Kernel/SemaTypes.HH"

#define CTRL_ALT_DEL		0
#define CTRL_ALT_C		1
#define CTRL_ALT_X		2
#define CTRL_ALT_TAB		3

#help_index "Hash"
#include "/Kernel/HashTypes.HH"

#include "/Kernel/SymbolTypes.HH"

#include "/Kernel/DocTypes.HH"

#help_index "Windows"
#include "/Kernel/WindowInhibitFlags.HH"

class CWinMgrTimingGlbls
{
  I64	last_total_jiffies,
	last_idle_pt_hits[MP_PROCESSORS_NUM],
	last_swap_cnter[MP_PROCESSORS_NUM];
  F64	last_calc_idle_time,calc_idle_delta_time;
  I64	calc_idle_cnt;
};

#define WINDOW_MANAGER_TIMING_DEFINED
#include "/Kernel/WindowManagerTypes.HH"

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
#include "/Kernel/FileMaskTypes.HH"

#help_index "File/Low Level"
#include "/Kernel/BlkDev/BlockSize.HH"
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
#include "/Kernel/DirEntryTypes.HH"

#help_index "File/Program Routines"
//File Util Flags
#include "/Kernel/FileFindFlags.HH"
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

#help_index "File/Low Level"
//See $LK,"ST_BLKDEV_TYPES",A="MN:ST_BLKDEV_TYPES"$
#include "/Kernel/BlkDev/BlockDevTypes.HH"

#include "/Kernel/BlkDev/BlockDevRecord.HH"

//Drive locked_flags

//See $LK,"ST_DRV_TYPES",A="MN:ST_DRV_TYPES"$
#include "/Kernel/BlkDev/FileSystemTypes.HH"
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

#include "/Kernel/BlkDev/FreeListTypes.HH"

#include "/Kernel/BlkDev/DriveTypes.HH"

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

#include "/Kernel/BlkDev/DirContextTypes.HH"

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

#include "/Kernel/ColorTypes.HH"

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

#include "/Kernel/ControlTypes.HH"

#include "/Kernel/WindowScrollTypes.HH"

public class CViewAngles
{
  I64	sx,sy,sz;
  F64	ax,ay,az;
  CColorROPU32 cx,cy,cz,cbd,cbg,cfg;
};

#help_index "Menus"
#include "/Kernel/MenuTypes.HH"

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
#include "/Kernel/JobTypes.HH"

#include "/Kernel/JobCtrlTypes.HH"

#include "/Kernel/MessageCodes.HH"

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
#include "/Kernel/TaskDisplayFlags.HH"

#include "/Kernel/TaskFlags.HH"

#include "/Kernel/DisplayFlags.HH"

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

#include "/Kernel/DiagnosticText.HH"

#include "/Kernel/ScanFlags.HH"

#include "/Kernel/ScanCodes.HH"

#include "/Kernel/TextGlobalsTypes.HH"

#include "/Kernel/GraphicsTypes.HH"

#help_index "Devices"
#include "/Kernel/VgaPorts.HH"

#help_index "Compression/Piece by Piece"
#include "/Kernel/Arc.HH"

#define "Char/Input;StdIn"
//GetStr flags
#define GSF_SHIFT_ESC_EXIT	1 //This kills task on <SHIFT-ESC>
#define GSF_WITH_NEW_LINE	2

#define "Char/Operations"
//Flags for StrUtil and MStrUtil
#include "/Kernel/StringUtilFlags.HH"

//Flags for StrFind
#include "/Kernel/StringFindFlags.HH"

#include "/Kernel/ListFlags.HH"

#help_index "Keyboard Devices/System"
#include "/Kernel/KeyDevTypes.HH"

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
#include "/Kernel/FunSegTypes.HH"

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
#include "/Kernel/StrPrintTypes.HH"

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
