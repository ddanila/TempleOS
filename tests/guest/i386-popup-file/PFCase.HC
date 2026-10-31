U8 *pf_marker="C:/PF.OUT";
if(Let2Drv('B',FALSE))pf_marker="B:/PF.OUT";
if(FileFind(pf_marker))FileWrite(pf_marker,"2",1);
else FileWrite(pf_marker,"1",1);
