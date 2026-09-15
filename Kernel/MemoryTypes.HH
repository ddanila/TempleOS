//Shared page-pool and heap records; caller supplies allocation records and CTask.

#help_index "Memory/BlkPool"

#define MBS_USED_SIGNATURE_VAL		'MBUs'
#define MBS_UNUSED_SIGNATURE_VAL	'MBUn'
class CMemBlk
{
  CMemBlk *next,*last;
  U32	mb_signature,pags;
};

#define MRT_UNUSED	0
#define MRT_RAM		1
#define MRT_DEV		2

class CMemRange
{
  CMemRange *next,*last;
  U32	type,flags;
  U8	*base;
  I64	size;
};

#define MEM_PAG_BITS		9
#define MEM_PAG_SIZE		(1<<MEM_PAG_BITS)
#define MEM_HEAP_HASH_SIZE	1024
#define MEM_FREE_PAG_HASH_SIZE	0x100
//It is common to $LK,"MAlloc",A="MN:MAlloc"$() exact powers of two.  There is some overhead.
//We add 2 pags, so a request is not rounded-up to next power of two.
#define MEM_EXTRA_HASH2_PAGS	2

#define MEM_ADAM_STK		(MEM_PAG_SIZE*512) //Like 16384*MEM_PAG_SIZE
#define MEM_SETH_STK		(MEM_PAG_SIZE*512)
#define MEM_INTERRUPT_STK	(MEM_PAG_SIZE*512)
#define MEM_DFT_STK		(MEM_PAG_SIZE*512)

#define TASK_HASH_TABLE_SIZE	(1<<10)

//locked flags
#define BPlf_LOCKED		0
public class CBlkPool
{
  I64	locked_flags,alloced_u8s,used_u8s;
  CMemBlk *mem_free_lst,
	*mem_free_2meg_lst, //This is for Sup1CodeScraps/Mem/Mem2Meg.HC.
	*free_pag_hash[MEM_FREE_PAG_HASH_SIZE],
	*free_pag_hash2[64-MEM_PAG_BITS];
};

#help_index "Memory/HeapCtrl"
//locked flags
#define HClf_LOCKED		0

#define HEAP_CTRL_SIGNATURE_VAL	'HcSV'
public class CHeapCtrl
{
  CBlkPool *bp;
  U32	hc_signature,pad;
  I64	locked_flags,alloced_u8s,used_u8s;
  CTask *mem_task;
  CMemBlk *next_mem_blk,*last_mem_blk;
  CMemBlk *last_mergable;
  CMemUnused *malloc_free_lst;
  CMemUsed *next_um,*last_um;
  CMemUnused *heap_hash[MEM_HEAP_HASH_SIZE/sizeof(U8 *)];
};
