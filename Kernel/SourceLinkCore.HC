I64 SrcLineNum(U8 *addr,I64 cnt=1)
{//linenum for src of addr.
  CHashSrcSym *tmph;
  I64 cur_line,first_line,last_line,num_lines,offset;
  CDbgInfo *dbg_info;
  U32 *body;
  U8 *src,*src2;
  if (tmph=FunSegFind(addr,&offset)) {
    if (tmph->type&(HTT_FUN|HTT_EXPORT_SYS_SYM)) {
      if (dbg_info=tmph->dbg_info) {
	num_lines=dbg_info->max_line-dbg_info->min_line+1;
	body=dbg_info->body;

	//find first nonzero
	first_line=0;
	while (!body[first_line]) {
	  first_line++;
	  if (first_line>=num_lines)
	    return -1;
	}

	//find last nonzero
	last_line=num_lines-1;
	while (!body[last_line] && last_line>first_line)
	  last_line--;

	  //interpolate to guess line num
	cur_line=ClampI64(ToF64(addr-body[first_line])*(last_line-first_line+1)/
	      (body[last_line]-body[first_line]+1),first_line,last_line);

	//retreat while too high
	while ((!body[cur_line] || body[cur_line]>=addr) && cur_line>first_line)
	  cur_line--;

	  //advance while to low
	while ((!body[cur_line] || body[cur_line]<addr) && cur_line<last_line)
	  cur_line++;

	if (addr<body[cur_line]+cnt)
	  return cur_line+dbg_info->min_line;

      } else if (tmph->src_link) {
	src =StrNew(tmph->src_link);
	src2=StrNew(tmph->src_link);
	StrLastRem(src,",",src2);
	cur_line=Str2I64(src2);
	Free(src);
	Free(src2);
	return cur_line;
      }
    }
  }
  return -1;
}

U8 *SrcFileName(U8 *addr,I64 cnt=1,CTask *mem_task=NULL)
{//MAlloc filename for src of addr.
  CHashSrcSym *tmph;
  I64 i,j,ii,offset,best=NULL,d,best_d;
  U32 *body;
  CDbgInfo *dbg_info;
  U8 *src;
  if ((tmph=FunSegFind(addr,&offset)) &&
	tmph->type&(HTT_FUN|HTT_EXPORT_SYS_SYM)) {
    if (dbg_info=tmph->dbg_info) {
      j=dbg_info->max_line-dbg_info->min_line+1;
      body=dbg_info->body;
      best_d=I64_MAX;
      for (i=0;i<j;i++) {
	if (0<body[i]<=addr<body[i]+cnt) {
	  ii=i+1;
	  while (!body[ii])
	    ii++;
	  if (addr<body[ii]) {
	    d=addr(I64)-body[i];
	    if (d<best_d) {
	      best_d=d;
	      best=tmph->src_link;
	    }
	  }
	}
      }
    } else
      best=tmph->src_link;
  }
  if (best) {
    src=StrNew(best,mem_task);
    StrFirstRem(src,":");
    StrLastRem(src,",");
    return src;
  } else
    return NULL;
}

U8 *SrcEdLink(U8 *addr,I64 cnt=1,CTask *mem_task=NULL)
{//MAlloc file,line link to src of addr.
  U8 *filename,*st,*st2;
  I64 linenum;
  if (filename=SrcFileName(addr,cnt)) {
    linenum=SrcLineNum(addr,cnt);
    if (linenum<1)
      linenum=1;
    st2=MStrPrint("FL:%s,%d",filename,linenum);
    Free(filename);
    st=StrNew(st2,mem_task);
    Free(st2);
    return st;
  }
  return NULL;
}
