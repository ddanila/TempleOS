//Shared public records; callers provide their declared dependencies.
#define JOBCf_LOCKED		0
class CJobCtrl
{
  CJob *next_waiting,*last_waiting;
  CJob *next_done,*last_done;
  I64	flags;
};
