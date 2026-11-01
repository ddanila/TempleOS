//Original TaskInit window defaults, parameterized by live display and drive state.
U0 TaskWindowDefaultsCore(CTask *task,I64 cols,I64 rows,U8 border_attr)
{
  task->win_inhibit=WIG_TASK_DFT;
  task->text_attr=WHITE<<4+BLUE;
  task->border_src=BDS_CONST;
  task->border_attr=border_attr;
  task->title_src=TTS_CONST;
  task->win_left=1;
  task->win_right=cols-2;
  task->win_top=13;
  task->win_bottom=rows-2;
}
