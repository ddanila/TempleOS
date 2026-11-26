"""Use the existing demo batch runner after a boot worker has completed a call."""
from pathlib import Path
import runpy
import sys

runner = Path('tools/test-i386-demo-batch.py')
main = runpy.run_path(str(runner))['main']
main.__globals__['FIXTURE'] += r'''
I64 DemoWorkerReady(U8 *unused)
{
  no_warn unused;
  return 1;
}
if(JobResGet(JobQue(&DemoWorkerReady,NULL,0,0))!=1)throw('Worker',TRUE);
'''
sys.argv.extend(['--demo', 'Demo/MultiCore/MPPrint.HC'])
main()
