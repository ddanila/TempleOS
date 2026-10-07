U0 WinMgrRefreshTime(CWinMgrGlbls *state,F64 t)
{//Original measured refresh policy; the caller supplies its actual refresh time.
  F64 t_delta;
  if ((t_delta=t-state->last_refresh_tS)>0.01)
    state->fps=Max(1.0/t_delta,1);
  else
    state->fps=99;
  state->last_refresh_tS=t;
}
