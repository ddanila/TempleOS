//Original servant dispatch bound to the retained job/message scheduler services.
#define TTS_TASK_NAME 2
#define WIG_USER_TASK_DFT 0x1000
I64 NativeSrvJobs(I64 flags) { return (*native_input_jobs)(flags,Fs); }
U0 NativeSrvFlush() { (*native_servant_flush)(Fs); }
U0 NativeSrvYield() { (*native_input_yield)(); }
#define JobsHndlr NativeSrvJobs
#define FlushMsgs NativeSrvFlush
#define Yield NativeSrvYield
#define SrvTaskCont NativeSrvTaskCont
#include "/Kernel/SrvTaskContCore.HC"
U0 NativeSrvCmdLine(I64 dummy=0)
{
  CHash *hook;
  U0 (*startup)();
  no_warn dummy;
  Fs->title_src=TTS_TASK_NAME;
  Fs->win_inhibit=WIG_USER_TASK_DFT;
  if(!ConsoleSource("#include \"/Kernel/I386/PublicUser.HH\"\n",
      "ServantHeaders.HC",I386_INPUT_ATOMIC_DEFINES|CCF_JUST_LOAD))
    throw('SrvHdr',TRUE);
  //CallExtStr with no arguments accepts functions and system exports and
  //does nothing when the symbol or executable address is absent.
  hook=HashFind("SrvStartUp",Fs->hash_table,HTT_FUN|HTT_EXPORT_SYS_SYM);
  if(hook) {
    if(hook->type&HTT_FUN) startup=hook(CHashFun *)->exe_addr;
    else startup=hook(CHashExport *)->val;
    if(startup) (*startup)();
  }
  NativeSrvTaskCont;
}
