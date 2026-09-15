//The live native scheduler embeds these complete public records.
#assert sizeof(CTask)==992
#assert sizeof(CCPU)==232
#assert sizeof(CJobCtrl)==24
#assert sizeof(CWinScroll)==32
#assert offset(CI386Task.context)==sizeof(CTask)
#assert offset(CI386Cpu.scheduler)==sizeof(CCPU)
#assert sizeof(CI386Task.catch_except)==1
#assert sizeof(CI386Task.except_rbp)==8
#assert offset(CTaskDying.wake_jiffy)==12
#assert offset(CTask.addr)==0
#assert offset(CTask.task_signature)==4
#assert offset(CTask.win_inhibit)==8
#assert offset(CTask.wake_jiffy)==12
#assert offset(CTask.task_flags)==20
#assert offset(CTask.display_flags)==24
#assert offset(CTask.code_heap)==28
#assert offset(CTask.data_heap)==32
#assert offset(CTask.put_doc)==36
#assert offset(CTask.display_doc)==40
#assert offset(CTask.border_doc)==44
#assert offset(CTask.win_left)==48
#assert offset(CTask.win_right)==56
#assert offset(CTask.win_top)==64
#assert offset(CTask.win_bottom)==72
#assert offset(CTask.cur_dv)==80
#assert offset(CTask.cur_dir)==84
#assert offset(CTask.parent_task)==88
#assert offset(CTask.next_task)==92
#assert offset(CTask.last_task)==96
#assert offset(CTask.next_input_filter_task)==100
#assert offset(CTask.last_input_filter_task)==104
#assert offset(CTask.next_sibling_task)==108
#assert offset(CTask.last_sibling_task)==112
#assert offset(CTask.next_child_task)==116
#assert offset(CTask.last_child_task)==120
#assert offset(CTask.win_width)==124
#assert offset(CTask.win_height)==132
#assert offset(CTask.pix_left)==140
#assert offset(CTask.pix_right)==148
#assert offset(CTask.pix_width)==156
#assert offset(CTask.pix_top)==164
#assert offset(CTask.pix_bottom)==172
#assert offset(CTask.pix_height)==180
#assert offset(CTask.scroll_x)==188
#assert offset(CTask.scroll_y)==196
#assert offset(CTask.scroll_z)==204
#assert offset(CTask.rip)==212
#assert offset(CTask.rflags)==220
#assert offset(CTask.rsp)==228
#assert offset(CTask.rsi)==236
#assert offset(CTask.rax)==244
#assert offset(CTask.rcx)==252
#assert offset(CTask.rdx)==260
#assert offset(CTask.rbx)==268
#assert offset(CTask.rbp)==276
#assert offset(CTask.rdi)==284
#assert offset(CTask.r8)==292
#assert offset(CTask.r9)==300
#assert offset(CTask.r10)==308
#assert offset(CTask.r11)==316
#assert offset(CTask.r12)==324
#assert offset(CTask.r13)==332
#assert offset(CTask.r14)==340
#assert offset(CTask.r15)==348
#assert offset(CTask.gs)==356
#assert offset(CTask.fpu_mmx)==360
#assert offset(CTask.swap_cnter)==364
#assert offset(CTask.draw_it)==372
#assert offset(CTask.task_title)==376
#assert offset(CTask.task_name)==520
#assert offset(CTask.wallpaper_data)==552
#assert offset(CTask.title_src)==696
#assert offset(CTask.border_src)==697
#assert offset(CTask.text_attr)==698
#assert offset(CTask.border_attr)==699
#assert offset(CTask.win_z_num)==700
#assert offset(CTask.stk)==704
#assert offset(CTask.next_except)==708
#assert offset(CTask.last_except)==712
#assert offset(CTask.except_rbp)==716
#assert offset(CTask.except_ch)==724
#assert offset(CTask.except_callers)==732
#assert offset(CTask.catch_except)==764
#assert offset(CTask.new_answer)==765
#assert offset(CTask.answer_type)==766
#assert offset(CTask.answer)==772
#assert offset(CTask.answer_time)==780
#assert offset(CTask.bpt_lst)==788
#assert offset(CTask.next_ctrl)==792
#assert offset(CTask.last_ctrl)==796
#assert offset(CTask.cur_menu)==800
#assert offset(CTask.next_settings)==804
#assert offset(CTask.next_ode)==808
#assert offset(CTask.last_ode)==812
#assert offset(CTask.last_ode_time)==816
#assert offset(CTask.hash_table)==824
#assert offset(CTask.srv_ctrl)==828
#assert offset(CTask.next_cc)==852
#assert offset(CTask.last_cc)==856
#assert offset(CTask.last_fun)==860
#assert offset(CTask.task_end_cb)==864
#assert offset(CTask.song_task)==868
#assert offset(CTask.animate_task)==872
#assert offset(CTask.rand_seed)==876
#assert offset(CTask.task_num)==884
#assert offset(CTask.fault_num)==892
#assert offset(CTask.fault_err_code)==900
#assert offset(CTask.popup_task)==908
#assert offset(CTask.dbg_task)==912
#assert offset(CTask.horz_scroll)==916
#assert offset(CTask.vert_scroll)==948
#assert offset(CTask.user_data)==980
_intern 0x15 CTask *ProbePublicFs();
_intern 0x17 CCPU *ProbePublicGs();
U0 ProbeTaskDraw(CTask *task,CDC *dc)
{ task->user_data=0x12345678ABCDEF01; }
U0 ProbeTaskLayout(CI386CompilerProbe *probe,CI386Heap *heap,CCmpCtrl *outer)
{
  CI386Task *live=I386TaskSelf;
  CTask *view=ProbePublicFs;
  CCPU *live_cpu=ProbePublicGs;
  if(view!=live || view->addr!=view || view->task_signature!=TASK_SIGNATURE_VAL ||
      view->gs!=live_cpu || live_cpu->addr!=live_cpu || live_cpu->num ||
      view->last_cc!=outer || view->hash_table!=live->hash_table ||
      !view->stk || view->stk->next_stk || view->stk->stk_ptr ||
      view->stk->stk_size<256 || ((&view->stk->stk_base)(U64)&7) ||
      GetRSP<(&view->stk->stk_base)(U64) ||
      GetRSP>=(&view->stk->stk_base)(U64)+view->stk->stk_size) KernelStop;
  I64 used=heap->used,allocations=heap->allocations,i;
  U32 flags=I386IrqSave;
  U8 *bytes=I386HeapAlloc(heap,sizeof(CTask)+8,TRUE);
  CTask *task=bytes;
  CCPU *cpu=I386HeapAlloc(heap,sizeof(CCPU),TRUE);
  I386IrqRestore(flags);
  if(!task || !cpu) KernelStop;
  for(i=0;i<8;i++) bytes[sizeof(CTask)+i]=0xA5;
  task->addr=task; task->gs=cpu; cpu->addr=cpu; cpu->seth_task=task;
  task->wake_jiffy=0x123456789ABCDEF0;
  task->except_ch=0xFEDCBA9876543210;
  task->catch_except=TRUE; task->new_answer=FALSE;
  task->srv_ctrl.flags=0x8000000000000001;
  task->horz_scroll.pos=0x100000002;
  task->r15=0xAABBCCDDEEFF0011;
  task->draw_it=&ProbeTaskDraw;
  task->draw_it(task,0);
  if(task->addr!=task || cpu->addr!=cpu || cpu->seth_task!=task || task->gs!=cpu ||
      task->wake_jiffy!=0x123456789ABCDEF0 || task->except_ch!=0xFEDCBA9876543210 ||
      !task->catch_except || task->new_answer || task->srv_ctrl.flags!=0x8000000000000001 ||
      task->horz_scroll.pos!=0x100000002 || task->r15!=0xAABBCCDDEEFF0011 ||
      task->user_data!=0x12345678ABCDEF01) KernelStop;
  for(i=0;i<8;i++) if(bytes[sizeof(CTask)+i]!=0xA5) KernelStop;
  flags=I386IrqSave;
  if(!I386HeapFree(heap,cpu) || !I386HeapFree(heap,bytes) ||
      heap->used!=used || heap->allocations!=allocations || !I386HeapValid(heap)) KernelStop;
  I386IrqRestore(flags);
  KernelLog("TASK LAYOUT "); KernelHex(probe->phase); KernelLog(" ");
  KernelHex(sizeof(CTask)); KernelLog(" "); KernelHex(sizeof(CCPU)); KernelLog("\n");
}
