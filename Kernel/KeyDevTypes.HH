#ifndef KERNEL_KEYDEV_TYPES_INCLUDED
#define KERNEL_KEYDEV_TYPES_INCLUDED
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

#endif
