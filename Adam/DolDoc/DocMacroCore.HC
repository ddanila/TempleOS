U0 SysMacroStripKey(CJob *macro_head,I64 arg1,I64 arg2)
{
  CJob *tmpc,*tmpc1;
  tmpc=macro_head->next;
  while (tmpc!=macro_head) {
    tmpc1=tmpc->next;
    if (tmpc->job_code==JOBT_MSG &&
	  (tmpc->msg_code==MSG_KEY_DOWN || tmpc->msg_code==MSG_KEY_UP ||
	  tmpc->msg_code==MSG_KEY_DOWN_UP) &&
	  arg1 && tmpc->aux1==arg1 || !arg1 && tmpc->aux2==arg2) {
      QueRem(tmpc);
      JobDel(tmpc);
    }
    tmpc=tmpc1;
  }
}

#define MT_NULL	0
#define MT_MSG	1
#define MT_CHAR	2

class CMacroTmp
{
  CMacroTmp *next,*last;
  I64 type;
  U8 buf[STR_LEN];
};

CMacroTmp *Cmd2MT(CJob *tmpc)
{
  U8 buf[8];
  CMacroTmp *tmpmt=CAlloc(sizeof(CMacroTmp));
  try {
    if (Bt(char_bmp_macro,tmpc->aux1) && tmpc->msg_code==MSG_KEY_DOWN) {
      tmpmt->type=MT_CHAR;
      buf[0]=tmpc->aux1;
      buf[1]=0;
      StrPrint(tmpmt->buf,"%Q",buf);
    } else {
      tmpmt->type=MT_MSG;
      StrPrint(tmpmt->buf,"Msg(0x%X,0x%X,0x%X);",
  	  tmpc->msg_code,tmpc->aux1,tmpc->aux2);
    }
  } catch { Free(tmpmt); }
  return tmpmt;
}

U8 *SysMacro2Str(CJob *macro_head)
{
  CJob *tmpc;
  I64 cnt=1; //terminating zero
  U8 *ptr,*m=NULL;
  CMacroTmp *tmpmt,*tmpmt1,head;
  LBtr(&sys_semas[SEMA_RECORD_MACRO],0);

  QueInit(&head);
  head.type=MT_NULL;
  try {
    tmpc=macro_head->next;
    while (tmpc!=macro_head) {
      tmpmt=Cmd2MT(tmpc);
      QueIns(tmpmt,head.last);
      cnt+=StrLen(tmpmt->buf);
      if (tmpmt->type==MT_CHAR) {
        if (tmpmt->last->type!=MT_CHAR)
  	cnt+=StrLen("\"");
        if (tmpmt->next->type!=MT_CHAR)
  	cnt+=StrLen("\";");
      }
      tmpc=tmpc->next;
    }

    m=MAlloc(cnt);
    ptr=m;

    tmpmt=head.next;
    while (tmpmt!=&head) {
      tmpmt1=tmpmt->next;
      if (tmpmt->type==MT_MSG) {
        StrCpy(ptr, tmpmt->buf);
        ptr+=StrLen(tmpmt->buf);
      } else {
        if (tmpmt->last->type!=MT_CHAR) {
  	StrCpy(ptr, "\"");
  	ptr+=StrLen("\"");
        }
        StrCpy(ptr,tmpmt->buf);
        ptr+=StrLen(tmpmt->buf);
        if (tmpmt->next->type!=MT_CHAR) {
  	StrCpy(ptr, "\";");
  	ptr+=StrLen("\";");
        }
      }
      tmpmt=tmpmt1;
    }
    *ptr=0;
  } catch {
    while(head.next!=&head) {
      tmpmt=head.next; QueRem(tmpmt); Free(tmpmt);
    }
    Free(m);
  }
  while(head.next!=&head) {
    tmpmt=head.next; QueRem(tmpmt); Free(tmpmt);
  }
  return m;
}

