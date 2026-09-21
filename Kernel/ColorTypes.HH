#ifndef COLOR_TYPES_INCLUDED
#define COLOR_TYPES_INCLUDED
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

#endif
