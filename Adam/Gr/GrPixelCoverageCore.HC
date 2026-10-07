//Portable equivalent of original _IS_PIX_COVERED0; caller clips coordinates.
Bool GrPixelCoveredCore(CTask *task,I64 x,I64 y)
{
  return task->win_z_num<gr.win_z_buf[(y>>3)*TEXT_COLS+(x>>3)];
}
