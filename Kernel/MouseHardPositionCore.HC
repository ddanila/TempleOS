#ifndef MOUSE_HARD_POSITION_CORE_INCLUDED
#define MOUSE_HARD_POSITION_CORE_INCLUDED
U0 MouseHardPositionCore(CD3I64 *prescale,CD3 *scale,CD3I64 *position,CMsStateGlbls *state,CGridGlbls *grid)
{
  I64 i;
  position->x=prescale->x*scale->x*grid->x_speed;
  position->y=prescale->y*scale->y*grid->y_speed;
  position->z=prescale->z*scale->z*grid->z_speed;

  i=Trunc(state->scale.x*position->x/grid->x)*grid->x+state->offset.x;
//TODO grid->x_offset?
  if (i<0)
    state->offset.x-=i;
  else if (i>=GR_WIDTH)
    state->offset.x+=GR_WIDTH-1-i;

  i=Trunc(state->scale.y*position->y/grid->y)*grid->y+state->offset.y;
  if (i<0)
    state->offset.y-=i;
  else if (i>=GR_HEIGHT)
    state->offset.y+=GR_HEIGHT-1-i;

}
#endif
