I64 WinQueIPMsgsCore(CMsStateGlbls *mouse,CMsStateGlbls *old,
  CMsStateGlbls *last,CD3I64 *single,F64 time,Bool que,
  U0 (*post)(CTask *task,I64 code,I64 a,I64 b))
{
  I64 msg_code=0,arg1,arg2,single_arg1,single_arg2;
  CTask *task_focus=sys_focus_task;

  if (task_focus && !winmgr.grab_scroll) {
    arg1=mouse->pos.x-task_focus->pix_left-task_focus->scroll_x;
    arg2=mouse->pos.y-task_focus->pix_top-task_focus->scroll_y;
    single_arg1=single->x-task_focus->pix_left-task_focus->scroll_x;
    single_arg2=single->y-task_focus->pix_top-task_focus->scroll_y;
    if (old->presnap.x!=mouse->presnap.x || old->presnap.y!=mouse->presnap.y) {
      if (que)
	(*post)(task_focus,MSG_MS_MOVE,arg1,arg2);
      msg_code=MSG_MS_MOVE;
    }
//TODO que msg for mouse->pos.z?
    if (mouse->left_dbl_time) {
      if (time>mouse->left_dbl_time) {
	if (mouse->left_dbl) {
	  if (!mouse->left_down_sent) {
	    if (que)
	      (*post)(task_focus,MSG_MS_L_D_DOWN,arg1,arg2);
	    mouse->left_down_sent=TRUE;
	    msg_code=MSG_MS_L_D_DOWN;
	  }
	  if (!mouse->lb) {
	    if (que)
	      (*post)(task_focus,MSG_MS_L_D_UP,arg1,arg2);
	    mouse->left_dbl_time=0;
	    msg_code=MSG_MS_L_D_UP;
	  }
	} else {
	  if (!mouse->left_down_sent) {
	    if (que)
	      (*post)(task_focus,MSG_MS_L_DOWN,single_arg1,single_arg2);
	    mouse->left_down_sent=TRUE;
	    msg_code=MSG_MS_L_DOWN;
	  }
	  if (!mouse->lb) {
	    if (que)
	      (*post)(task_focus,MSG_MS_L_UP,arg1,arg2);
	    mouse->left_dbl_time=0;
	    msg_code=MSG_MS_L_UP;
	  }
	}
      } else {
	if (mouse->lb && !last->lb) {
	  mouse->left_dbl_time=time;
	  mouse->left_dbl=TRUE;
	}
      }
    } else {
      if (TaskValidate(task_focus) &&
	    Bt(&task_focus->win_inhibit,WIf_FOCUS_TASK_MS_L_D)) {
	if (mouse->lb  && !last->lb) {
	  if (que)
	    (*post)(task_focus,MSG_MS_L_DOWN,arg1,arg2);
	  msg_code=MSG_MS_L_DOWN;
	} else if (!mouse->lb && last->lb) {
	  if (que)
	    (*post)(task_focus,MSG_MS_L_UP,arg1,arg2);
	  msg_code=MSG_MS_L_UP;
	}
      } else {
	if (mouse->lb  && !last->lb) {
	  mouse->left_dbl=FALSE;
	  mouse->left_down_sent=FALSE;
	  mouse->left_dbl_time=time+mouse->dbl_time;
	  single->x=mouse->pos.x;
	  single->y=mouse->pos.y;
	}
      }
    }

    if (mouse->right_dbl_time) {
      if (time>mouse->right_dbl_time) {
	if (mouse->right_dbl) {
	  if (!mouse->right_down_sent) {
	    if (que)
	      (*post)(task_focus,MSG_MS_R_D_DOWN,arg1,arg2);
	    mouse->right_down_sent=TRUE;
	    msg_code=MSG_MS_R_D_DOWN;
	  }
	  if (!mouse->rb) {
	    if (que)
	      (*post)(task_focus,MSG_MS_R_D_UP,arg1,arg2);
	    mouse->right_dbl_time=0;
	    msg_code=MSG_MS_R_D_UP;
	  }
	} else {
	  if (!mouse->right_down_sent) {
	    if (que)
	      (*post)(task_focus,MSG_MS_R_DOWN,single_arg1,single_arg2);
	    mouse->right_down_sent=TRUE;
	    msg_code=MSG_MS_R_DOWN;
	  }
	  if (!mouse->rb) {
	    if (que)
	      (*post)(task_focus,MSG_MS_R_UP,arg1,arg2);
	    mouse->right_dbl_time=0;
	    msg_code=MSG_MS_R_UP;
	  }
	}
      } else {
	if (mouse->rb && !last->rb) {
	  mouse->right_dbl_time=time;
	  mouse->right_dbl=TRUE;
	}
      }
    } else {
      if (TaskValidate(task_focus) &&
	    Bt(&task_focus->win_inhibit,WIf_FOCUS_TASK_MS_R_D)) {
	if (mouse->rb  && !last->rb) {
	  if (que)
	    (*post)(task_focus,MSG_MS_R_DOWN,arg1,arg2);
	  msg_code=MSG_MS_R_DOWN;
	} else if (!mouse->rb && last->rb) {
	  if (que)
	    (*post)(task_focus,MSG_MS_R_UP,arg1,arg2);
	  msg_code=MSG_MS_R_UP;
	}
      } else {
	if (mouse->rb  && !last->rb) {
	  mouse->right_dbl=FALSE;
	  mouse->right_down_sent=FALSE;
	  mouse->right_dbl_time=time+mouse->dbl_time;
	  single->x=mouse->pos.x;
	  single->y=mouse->pos.y;
	}
      }
    }

    MemCpy(last,mouse,sizeof(CMsStateGlbls));
    MemCpy(old,mouse,sizeof(CMsStateGlbls));
  }
  return msg_code;
}
