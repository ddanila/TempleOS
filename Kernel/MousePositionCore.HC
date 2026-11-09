#ifndef MOUSE_POSITION_CORE_INCLUDED
#define MOUSE_POSITION_CORE_INCLUDED
U0 MousePositionCore(CMsStateGlbls *state,CGridGlbls *grid,I64 x,I64 y,I64 z,I64 cols,I64 rows)
{
  state->presnap.x=ToI64(state->scale.x*x)+state->offset.x;
  state->presnap.y=ToI64(state->scale.y*y)+state->offset.y;
  state->presnap.z=ToI64(state->scale.z*z)+state->offset.z;
  if (grid->snap) {
    state->pos.x=Trunc(state->presnap.x/grid->x)*grid->x+grid->x_offset;
    state->pos.y=Trunc(state->presnap.y/grid->y)*grid->y+grid->y_offset;
    state->pos.z=Trunc(state->presnap.z/grid->z)*grid->z+grid->z_offset;
  } else {
    state->pos.x=state->presnap.x;
    state->pos.y=state->presnap.y;
    state->pos.z=state->presnap.z;
  }

  state->pos.x=ClampI64(state->pos.x,0,GR_WIDTH-1);
  state->pos.y=ClampI64(state->pos.y,0,GR_HEIGHT-1);
  state->pos_text.x=state->pos.x/FONT_WIDTH;
  if (state->pos_text.x>=cols) {
    state->pos_text.x=cols-1;
    state->pos.x=cols*FONT_WIDTH-1;
  }
  state->pos_text.y=state->pos.y/FONT_HEIGHT;
  if (state->pos_text.y>=rows) {
    state->pos_text.y=rows-1;
    state->pos.y=rows*FONT_HEIGHT-1;
  }
}
#endif
