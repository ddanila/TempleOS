U0 Report(U8 *s){while(*s)OutU8(0xE9,*s++);}
#include "::/DocRead.HC"
I64 *v=CAlloc(80);
Report("READ 0 begin\n");v[0]=DRContract("T:/Reader0.DD",0,FALSE);Report("READ end\n");
Report("READ 1 begin\n");v[1]=DRContract("T:/Reader1.DD",1,FALSE);Report("READ end\n");
Report("READ 2 begin\n");v[2]=DRContract("T:/Reader2.DD",2,FALSE);Report("READ end\n");
Report("READ 3 begin\n");v[3]=DRContract("T:/Reader3.DD",3,FALSE);Report("READ end\n");
Report("READ 4 begin\n");v[4]=DRContract("T:/Reader4.DD",4,FALSE);Report("READ end\n");
Report("READ 5 begin\n");v[5]=DRContract("T:/Reader5.DD",5,FALSE);Report("READ end\n");
Report("READ 6 begin\n");v[6]=DRContract("T:/Reader6.DD",6,FALSE);Report("READ end\n");
Report("READ 7 begin\n");v[7]=DRContract("T:/Reader7.DD",7,FALSE);Report("READ end\n");
Report("READ 8 begin\n");v[8]=DRContract("T:/Reader8.DD",8,FALSE);Report("READ end\n");
Report("READ 9 begin\n");v[9]=DRContract("T:/Reader9.DD",9,FALSE);Report("READ end\n");
U8 *line=MStrPrint("EXPORT doc-read.bin %X %X\n",v,80);Report(line);Free(line);
Report("DONE original document read\n");
