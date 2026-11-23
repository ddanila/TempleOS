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

