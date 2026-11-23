#include "/Kernel/I386/PublicTask.HH"
I64 power_ready[2],power_go;
F64 PowerWorkerValue(F64 base,F64 exponent)
{
  return base`exponent;
}

U0 PowerWorker(U8 *argument)
{
  I64 index=argument;
  U64 actual,expected;
  U8 *p="POWER worker failed\n";
  power_ready[index]=1;
  while (!power_go || !power_ready[0] || !power_ready[1]) Sleep(1);
  try {
    if (index) {
      actual=PowerWorkerValue(3,2)(U64);
      expected=0x4021FFFFFFFFFFFF;
    } else {
      actual=PowerWorkerValue(9,0.5)(U64);
      expected=0x4007FFFFFFFFFFFF;
    }
    if (actual==expected) {
      if (index) p="POWER worker two exact\n";
      else p="POWER worker one exact\n";
    }
  } catch {
    Fs->catch_except=TRUE;
  }
  while (*p) OutU8(0xE9,*p++);
}

U0 PowerConcurrent()
{
  Spawn(&PowerWorker,0,"Power one");
  Spawn(&PowerWorker,1,"Power two");
  power_go=1;
}
