#ifndef KEYBOARD_STATE_TYPES_INCLUDED
#define KEYBOARD_STATE_TYPES_INCLUDED
#include "/Kernel/FifoTypes.HH"
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
#endif
