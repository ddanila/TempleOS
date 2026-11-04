U0 ACDProbeLog(U8 *s){while(*s)OutU8(0xE9,*s++);}
U8 *acd_probe_report;
I64 acd_probe_words,acd_probe_bytes,acd_probe_task,acd_probe_report_size;
public U0 ACDictionaryStart()
{
  U8 *line;
  ACDProbeLog("AC DICTIONARY init begin\n");
  ACInit;
  if(!TaskValidate(ac.task) || !ac.hash_table || !acd.word_lst ||
      !acd.has_words || !acd.has_defs || ac.num_words ||
      acd.word_lst_size!=1253930 || acd.num_words<1000 ||
      !Bt(&sys_run_level,RLf_AUTO_COMPLETE) || Bt(&ac.flags,ACf_INIT_IN_PROGRESS))throw('ACInit',TRUE);
  if(AutoCompleteSize<=acd.word_lst_size)throw('ACSize',TRUE);
  acd_probe_words=acd.num_words;acd_probe_bytes=acd.word_lst_size;acd_probe_task=ac.task->task_num;
  line=MStrPrint("AC DICTIONARY ready %d %d %d\n",acd.num_words,acd.word_lst_size,AutoCompleteSize);
  ACDProbeLog(line);Free(line);
}
U0 ACDAppend(U8 *bytes,I64 size)
{
  if(size<0 || acd_probe_report_size+size>65536)throw('ACReport',TRUE);
  MemCpy(acd_probe_report+acd_probe_report_size,bytes,size);acd_probe_report_size+=size;
}
U0 ACDField(U8 *label,U8 *bytes,I64 size)
{
  U8 *line=MStrPrint("%s %d\n",label,size);
  ACDAppend(line,StrLen(line));Free(line);
  if(size>0)ACDAppend(bytes,size);
  ACDAppend("\n",1);
}
I64 ACDRecordBytes(U8 *record)
{
  U8 *ptr=record,*end=record+MSize(record);
  if(*ptr++!=ACD_WORD_CHAR)throw('ACRecord',TRUE);
  ptr+=StrLen(ptr)+1;
  while(ptr<end && *ptr) {
    if(*ptr<ACD_DEF_CHAR || *ptr>ACD_EXTRA_CHAR)throw('ACRecord',TRUE);
    ptr++;ptr+=StrLen(ptr)+1;
  }
  if(ptr>=end)throw('ACRecord',TRUE);
  return ptr-record+1;
}
public U0 ACDictionaryReport()
{
  U8 *names="apple\0temple\0computer\0",*name=names,*first,*second,*all,*word,*line;
  I64 first_len,second_len,all_len;
  CHashGeneric *entry;
  CFile *file;
  U8 *upper,*block,*scan;
  I64 read_ok,match;
  acd_probe_report=MAlloc(65536);acd_probe_report_size=0;
  line=MStrPrint("WORDS %d BYTES %d\n",acd_probe_words,acd_probe_bytes);
  ACDAppend(line,StrLen(line));Free(line);
  while(*name) {
    upper=MStrUtil(name,SUF_TO_UPPER);entry=HashFind(upper,ac.hash_table,HTT_DICT_WORD);Free(upper);
    line=MStrPrint("AC DICTIONARY index %s %X\n",name,entry);ACDProbeLog(line);Free(line);
    if(entry) {
      file=FOpen(ACD_DEF_FILENAME,"r");
      if(file) {
        block=CAlloc(ACD_BLK_SIZE*2+1);read_ok=FBlkRead(file,block,entry->user_data0*ACD_BLK_SIZE/BLK_SIZE,ACD_BLK_SIZE*2/BLK_SIZE);match=-1;
        for(scan=block;scan<block+ACD_BLK_SIZE*2;scan++)if(*scan==ACD_WORD_CHAR && !StrICmp(name,scan+1)){match=scan-block;break;}
        line=MStrPrint("AC DICTIONARY block %s %d %d %d %d %X\n",name,entry->user_data0,FSize(file),read_ok,match,block(U64 *)[0]);ACDProbeLog(line);Free(line);
        Free(block);FClose(file);
      } else ACDProbeLog("AC DICTIONARY file missing\n");
    }
    first=ACDDefGet(name);second=ACDDefGet(name,2);all=ACDDefsGet(name);word=ACDWordPtAt(name);
    line=MStrPrint("AC DICTIONARY pointers %s %X %X %X %X\n",name,first,second,all,word);
    ACDProbeLog(line);Free(line);
    if(word){line=MStrPrint("AC DICTIONARY word %s %d\n",word+1,StrICmp(word+1,name));ACDProbeLog(line);Free(line);}
    if(!first || !all || !word || StrICmp(word+1,name))throw('ACDef',TRUE);
    first_len=StrLen(first);second_len=-1;if(second)second_len=StrLen(second);
    all_len=ACDRecordBytes(all);
    line=MStrPrint("AC DICTIONARY lookup %s %d %d %d\n",name,first_len,second_len,all_len);
    ACDProbeLog(line);Free(line);
    line=MStrPrint("WORD %s\n",name);ACDAppend(line,StrLen(line));Free(line);
    ACDField("FIRST",first,first_len);ACDField("SECOND",second,second_len);ACDField("ALL",all,all_len);
    Free(first);Free(second);Free(all);name+=StrLen(name)+1;
  }
  first=ACDDefGet("ZZZZ_IMPOSSIBLE_DICTIONARY_ENTRY");
  if(first){Free(first);throw('ACMiss',TRUE);}
  ACDProbeLog("AC DICTIONARY report ready\n");
}
public U0 ACDictionaryStop()
{
  CTask *old=ac.task;
  if(!AutoComplete(OFF))throw('ACStop',TRUE);
  DeathWait(&old);
  if(TaskValidate(ac.task))throw('ACStop',TRUE);
  ACDProbeLog("AC DICTIONARY stopped\n");
}
public U0 ACDictionaryCycle()
{
  I64 old_task=acd_probe_task,old_words=acd_probe_words,old_bytes=acd_probe_bytes;
  ACDictionaryStop;
  ACDictionaryStart;
  if(ac.task->task_num==old_task || acd.num_words!=old_words || acd.word_lst_size!=old_bytes)throw('ACCycle',TRUE);
  ACDictionaryStop;
  ACDProbeLog("PASS autocomplete dictionary\n");
}

public U0 ACDictionaryExport()
{
  U8 *line;
  ACDictionaryReport;
  line=MStrPrint("EXPORT ACDictionary.DATA %X %X\n",acd_probe_report,acd_probe_report_size);
  ACDProbeLog(line);Free(line);
}
public U0 ACDictionaryWrite()
{
  ACDictionaryReport;
  if(!FileWrite("C:/ACDictionary.DATA",acd_probe_report,acd_probe_report_size))throw('ACWrite',TRUE);
  Free(acd_probe_report);acd_probe_report=NULL;
}

ACDProbeLog("AC DICTIONARY fixture loaded\n");
