#ifndef MOUSE_STATE_TYPES_INCLUDED
#define MOUSE_STATE_TYPES_INCLUDED
#include "/Kernel/GeometryTypes.HH"
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

#endif
