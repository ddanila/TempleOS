from pathlib import Path
import json
import runpy
import struct
import sys

out = Path(__file__).resolve().parent
runner = Path('tools/test-i386-psalmody-keyboard.py').resolve()
archive = '/Apps/Psalmody/PsalmodyMain.HC'
source = Path('Apps/Psalmody/PsalmodyMain.HC').read_bytes()
helper = b"""U0 PsmTimingTrace(I64 event,I64 pitch,F64 start,F64 end,F64 tempo)
{
  U8 line[160],*p=line;
  StrPrint(line,"PS timing %d %d %d %d %d\\n",event,pitch,
    ToI64(start*1000),ToI64(end*1000),ToI64(tempo*1000));
  while(*p)OutU8(0xE9,*p++);
}

"""
start = b'\t    note_down_time=tS;'
finish = b'\t    PsmSetWidth(tmpn);'
duration = b'U8 PsmCvtDuration(F64 d)'
for marker in (start, finish, duration):
    assert source.count(marker) == 1
scan = b"""I64 PsmTimedGetMsg(I64 *arg1,I64 *arg2,I64 mask)
{
  I64 code,arrival,dispatch;
  I64 (*scan)(I64 *,I64 *,I64,CTask *,I64 *);
  CHashExport *symbol=HashFind("I386ScanKeyTimed",Fs->hash_table,HTT_EXPORT_SYS_SYM);
  U8 line[160],*p=line;
  if(!symbol)throw('PSTimed',TRUE);
  scan=symbol->val;
  LBtr(&Fs->task_flags,TASKf_IDLE);
  while(!(code=(*scan)(arg1,arg2,mask,Fs,&arrival))) {
    LBts(&Fs->task_flags,TASKf_IDLE);
    Yield;
  }
  LBtr(&Fs->task_flags,TASKf_IDLE);
  if(code==MSG_KEY_DOWN || code==MSG_KEY_UP) {
    dispatch=ToI64(tS*1000);
    StrPrint(line,"PS queue %d %d %d %d %d\\n",code,*arg1,*arg2,arrival,dispatch);
    while(*p)OutU8(0xE9,*p++);
  }
  return code;
}

"""
call = b'msg_code=GetMsg(&arg1,&arg2,1<<MSG_KEY_DOWN'
assert source.count(call) == 2
source = source.replace(call, b'msg_code=PsmTimedGetMsg(&arg1,&arg2,1<<MSG_KEY_DOWN')
helper += scan

source = source.replace(duration, helper + duration)
source = source.replace(start, start + b'\n\t    PsmTimingTrace(1,ona,note_down_time,evt_time,music.tempo);')
source = source.replace(finish, b'\t    PsmTimingTrace(2,tmpn->ona,note_down_time,evt_time,music.tempo);\n' + finish)
(out/'PsalmodyMain.HC').write_bytes(source)
payload = source

def diagnostic_package(pack, image, working, fixture):
    original = pack['snapshot']
    package = pack['package']
    def snapshot(raw):
        tree, files, dirs = original(raw)
        entry = tree['Apps'][2]['Psalmody'][2]
        name = Path(archive).name
        attr, stamp, _ = entry[name]
        entry[name] = files[archive] = (attr, stamp, payload)
        return tree, files, dirs
    package.__globals__['snapshot'] = snapshot
    try:
        report = package(image, working, additions={'/Probe/PsalmodyKeyboard.HC':fixture})
    finally:
        package.__globals__['snapshot'] = original
    before = original(image.read_bytes())[1]
    after = original(working.read_bytes())[1]
    assert {key for key in before.keys() | after.keys()
            if before.get(key) != after.get(key)} == {archive, '/Probe/PsalmodyKeyboard.HC'}
    assert after[archive][2] == payload
    return report

text = runner.read_text()
start = text.index("image=out/'working.img';")
end = text.index('\n', start)
text = text[:start] + ("image=out/'working.img';report['packaging']="
    "diagnostic_package(pack,args.disk.resolve(),image,fixture.read_bytes());"
    "report['scope']='Diagnostic overlay with guest note event timestamps'") + text[end:]
text = text.replace("if changed!={'/Probe/PsalmodyKeyboard.HC'}:", "if changed!={'/Probe/PsalmodyKeyboard.HC', archive}:")
text = text.replace("        verify(records)", """        report['timing'] = [line for line in g.collect().splitlines() if line.startswith(('PS timing ', 'PS queue '))]
        verify(records)""")
exec(compile(text, str(runner), 'exec'), {'__file__':str(runner), '__name__':'__main__',
     'diagnostic_package':diagnostic_package, 'archive':archive})
