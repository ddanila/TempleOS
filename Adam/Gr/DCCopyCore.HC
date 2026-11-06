public CDC *DCCopy(CDC *dc,CTask *task=NULL)
{//Alloc copy of dc, including image body, rot mat and depth buf.
  CDC *res;
  if (!dc) return NULL;
  if (dc->dc_signature!=DCS_SIGNATURE_VAL)
    throw('Graphics');
  res=MAllocIdent(dc,task);
  DCMat4x4Set(res,Mat4x4New(dc->r,task));
  res->mem_task=task;
  res->body=MAllocIdent(dc->body,task);
  res->depth_buf=MAllocIdent(dc->depth_buf,task);
  return res;
}

