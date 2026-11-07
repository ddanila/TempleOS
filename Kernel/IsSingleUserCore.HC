Bool IsSingleUser()
{//Return single-user mode.
  return Bt(&sys_semas[SEMA_SINGLE_USER],0);
}

