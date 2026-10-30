#include "/Kernel/ArcSeed.HC"
//See $LK,"::/Doc/Credits.DD"$.
//See $LK,"CArcCompress",A="MN:CArcCompress"$, $LK,"CArcEntry",A="MN:CArcEntry"$, and $LK,"CArcCtrl",A="MN:CArcCtrl"$

asm {
/****
U0 ArcEntryGet(CArcCtrl *c)
{
  I64 i;
  CArcEntry *tmp,*tmp1;

  if (c->entry_used) {
    i=c->free_idx;

    c->entry_used=FALSE;
    c->cur_entry=c->next_entry;
    c->cur_bits_in_use=c->next_bits_in_use;
    if (c->next_bits_in_use<ARC_BITS_MAX) {
      c->next_entry = &c->compress[i++];
      if (i==c->free_limit) {
	c->next_bits_in_use++;
	c->free_limit=1<<c->next_bits_in_use;
      }
    } else {
      do if (++i==c->free_limit)
	  i=c->min_table_entry;
      while (c->hash[i]);
      tmp=&c->compress[i];
      c->next_entry=tmp;
      tmp1=&c->hash[tmp->basecode];
      while (tmp1) {
	if (tmp1->next==tmp) {
	  tmp1->next=tmp->next;
	  break;
	} else
	  tmp1=tmp1->next;
      }
    }
    c->free_idx=i;
  }
}
****/
_ARC_ENTRY_GET::
	PUSH	RBP
	MOV	RBP,RSP
	PUSH	RSI
	PUSH	RDI
	MOV	RSI,U64 SF_ARG1[RBP]
	BTR	U64 CArcCtrl.entry_used[RSI],0
	JNC	I32 @@30
	MOV	RDX,U64 CArcCtrl.free_idx[RSI]
	MOV	RAX,U64 CArcCtrl.next_entry[RSI]
	MOV	U64 CArcCtrl.cur_entry[RSI],RAX
	MOV	RCX,U64 CArcCtrl.next_bits_in_use[RSI]
	MOV	U64 CArcCtrl.cur_bits_in_use[RSI],RCX
	CMP	RCX,ARC_BITS_MAX
	JAE	@@05
	MOV	RAX,RDX
	SHL	RAX,4
	LEA	RAX,U64 CArcCtrl.compress[RSI+RAX]
	MOV	U64 CArcCtrl.next_entry[RSI],RAX
	INC	RDX
	CMP	U64 CArcCtrl.free_limit[RSI],RDX
	JNE	@@25
	INC	RCX
	MOV	U64 CArcCtrl.next_bits_in_use[RSI],RCX
	MOV	RAX,1
	SHL	RAX,CL
	MOV	U64 CArcCtrl.free_limit[RSI],RAX
	JMP	@@25
@@05:	INC	RDX
	CMP	U64 CArcCtrl.free_limit[RSI],RDX
	JNE	@@10
	MOV	RDX,U64 CArcCtrl.min_table_entry[RSI]
@@10:	MOV	RAX,U64 CArcCtrl.hash[RSI+RDX*8]
	TEST	RAX,RAX
	JNZ	@@05
	MOV	RDI,RDX
	SHL	RDI,4
	LEA	RDI,U64 CArcCtrl.compress[RSI+RDI]
	MOV	U32 CArcCtrl.next_entry[RSI],EDI
	MOVZX	RBX,U16 CArcEntry.basecode[RDI]
	LEA	RCX,U64 CArcCtrl.hash[RSI+RBX*8]
@@15:	TEST	RCX,RCX
	JZ	@@25
	MOV	RAX,U64 CArcEntry.next[RCX]
	CMP	RDI,RAX
	JNE	@@20
	MOV	RAX,U64 CArcEntry.next[RDI]
	MOV	U64 CArcEntry.next[RCX],RAX
	JMP	@@25
@@20:	MOV	RCX,RAX
	JMP	@@15
@@25:	MOV	U64 CArcCtrl.free_idx[RSI],RDX
@@30:	POP	RDI
	POP	RSI
	POP	RBP
	RET1	8
}

_extern _ARC_ENTRY_GET U0 ArcEntryGet(CArcCtrl *c);

#include "/Kernel/ArcCompressCore.HC"

#include "/Kernel/ArcExpand.HC"
#include "/Kernel/ExpandBufCore.HC"

#include "/Kernel/CompressBufCore.HC"
