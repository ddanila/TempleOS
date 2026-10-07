#ifndef WINDOW_MANAGER_TYPES_INCLUDED
#define WINDOW_MANAGER_TYPES_INCLUDED
#ifndef WINDOW_MANAGER_TIMING_DEFINED
extern class CWinMgrTimingGlbls;
#endif
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

#endif
