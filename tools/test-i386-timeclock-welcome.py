#!/usr/bin/env python3
"""Check TimeClock report bytes with the original welcome document present."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy
import subprocess
import time

ROOT=Path(__file__).resolve().parents[1]
PLAIN={'\\':'backslash','|':'backslash','~':'grave_accent','^':'6','%':'5','#':'3','$':'4','!':'1','<':'comma','>':'dot',',':'comma',"'":'apostrophe',' ':'spc',';':'semicolon','.':'dot','-':'minus','=':'equal','/':'slash','?':'slash','(':'9',')':'0','{':'bracket_left','}':'bracket_right','*':'8','+':'equal','&':'7','_':'minus','[':'bracket_left',']':'bracket_right','"':'apostrophe',':':'semicolon'}
SHIFTED=set('(){}*+&_"<>#!%$|~:?^')


def guest(image,out,commands,ram_mib=64):
    out.mkdir(); log=out/'debug.log'
    cmd=['qemu-system-i386','-machine','pc','-accel','tcg','-cpu','486,-fpu','-m',str(ram_mib),'-nic','none','-drive',f'file={image},format=raw,if=ide','-display','none','-no-reboot','-debugcon',f'file:{log}','-qmp','stdio']
    p=subprocess.Popen(cmd,stdin=subprocess.PIPE,stdout=subprocess.PIPE,stderr=subprocess.DEVNULL,text=True,bufsize=1)
    def reply():
        while True:
            line=p.stdout.readline()
            if not line:raise RuntimeError('QEMU closed QMP')
            result=json.loads(line)
            if 'error' in result:raise RuntimeError(str(result))
            if 'return' in result:return result['return']
    def call(name,**args):
        p.stdin.write(json.dumps({'execute':name,'arguments':args})+'\n');p.stdin.flush();return reply()
    def wait(predicate,timeout=180):
        end=time.monotonic()+timeout
        while time.monotonic()<end and p.poll() is None:
            text=log.read_text() if log.exists() else ''
            if predicate(text):return text
            time.sleep(.1)
        raise TimeoutError('Guest log wait failed')
    def key(name,down):
        call('input-send-event',events=[{'type':'key','data':{'down':down,'key':{'type':'qcode','data':name}}}])
    def press(name):key(name,True);key(name,False)
    try:
        json.loads(p.stdout.readline());call('qmp_capabilities')
        wait(lambda text:'DONE native kernel startup\n' in text)
        time.sleep(5);call('screendump',filename=str(out/'initial.ppm'))
        for source in commands:
            start=len(log.read_text())
            for ch in source:
                shift=ch.isupper() or ch in SHIFTED; name=PLAIN.get(ch,ch.lower())
                if shift:key('shift',True)
                press(name)
                if shift:key('shift',False)
                time.sleep(.3)
            press('ret')
            text=wait(lambda s:any(marker in s[start:] for marker in ('COMMAND OK\n','INPUT REJECT ','COMMAND ERROR\n')))
            if 'INPUT REJECT ' in text[start:] or 'COMMAND ERROR\n' in text[start:]:raise ValueError(text[start:][-500:])
            if 'INPUT LINE '+source+'\n' not in text[start:]:raise ValueError('Incorrect input line: '+source)
            #The log marker precedes the console task returning to its input loop.
            time.sleep(3)
        call('quit')
    finally:
        if p.poll() is None:p.terminate()
        p.wait(timeout=15)


def main():
    ap=argparse.ArgumentParser(description=__doc__);ap.add_argument('disk',type=Path);ap.add_argument('--out',type=Path,required=True);args=ap.parse_args()
    out=args.out.resolve();source=args.disk.resolve()
    if out.exists():ap.error('Use a fresh output directory')
    out.mkdir(parents=True);image=out/'working.img'
    fixture=ROOT/'tests/guest/i386-timeclock-report-native/Contract.HC';gold_path=ROOT/'tests/i386/timeclock-reference.json'
    paths=[source,fixture,gold_path,Path(__file__).resolve(),ROOT/'tools/package-i386-native-image.py',ROOT/'tools/build-i386-kernel.py']
    sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
    pins={str(p):sha(p) for p in paths};gold=json.loads(gold_path.read_text())
    report=dict(result='running',input_sha256=pins,scope='Keyboard/log-driven native TimeClock record and exact report bytes with welcome, including cold reboot; no VGA pixel oracle or full desktop qualification')
    try:
        report['packaging']=runpy.run_path(str(ROOT/'tools/package-i386-native-image.py'))['package'](source,image,additions={'/ReportNative.HC':fixture.read_bytes()})
        guest(image,out/'first',['#include "C:/ReportNative.HC"','TimeReportSeed;','6*7;'])
        read=runpy.run_path(str(ROOT/'tools/build-i386-kernel.py'))['mutated_file_contents']
        files=read(image,{'/report-records.DATA','/report-first.DD','/ReportNative.HC'})
        if files['/ReportNative.HC']!=fixture.read_bytes():raise ValueError('Fixture changed')
        if files['/report-records.DATA']!=bytes.fromhex(gold['logical_file_hex']):raise ValueError('Records differ from original')
        expected=gold['report_latin1'].encode('latin1')
        if files['/report-first.DD']!=expected:raise ValueError('Report differs from original')
        guest(image,out/'reopen',['#include "C:/ReportNative.HC"','TimeReportCapture("C:/report-reopened.DD");','6*7;'])
        if read(image,{'/report-reopened.DD'})['/report-reopened.DD']!=expected:raise ValueError('Cold-reboot report differs')
        report.update(result='pass',report_sha256=hashlib.sha256(expected).hexdigest(),records_sha256=hashlib.sha256(files['/report-records.DATA']).hexdigest())
    except Exception as exc:
        report.update(result='fail',error=str(exc));raise
    finally:
        report['inputs_unchanged']=all(sha(Path(path))==digest for path,digest in pins.items())
        if not report['inputs_unchanged']:report.update(result='fail',error='Inputs changed')
        (out/'result.json').write_text(json.dumps(report,indent=2)+'\n')
    if report['result']!='pass':raise ValueError(report['error'])


if __name__=='__main__':main()
