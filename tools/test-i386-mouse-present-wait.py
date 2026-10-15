#!/usr/bin/env python3
"""Check real mouse-overlay contention, cancellation and displayed-backing transitions."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy
import shutil

ROOT = Path(__file__).resolve().parents[1]
COMMANDS = [('#include "/Kernel/I386/PublicUser.HH"', []),
 ('CTask *mp_owner,*mp_holder;I64 mp_mode,mp_before,mp_packets,mp_x,mp_y,mp_buttons;Bool '
  'mp_release,mp_stage,mp_frame_done;',
  []),
 ('U0 MPLog(U8 *s){while(*s)OutU8(0xE9,*s++);}', []),
 ('U0 MPMark(U8 *s){MPLog(s);OutU8(0xE9,48+mp_mode);OutU8(0xE9,10);}', []),
 ('U0 MPTurn(){I64 i;for(i=0;i<16;i++)Yield;}', []),
 ('U0 MPDraw(CDC *dc){DCFill(dc,BLUE);mp_stage=TRUE;while(!mp_release)Yield;}', []),
 ('U0 MPHolder(U8 *data){NativeGraphicsPresent(&MPDraw);mp_frame_done=TRUE;}', []),
 ('U0 MPStart(I64 '
  'mode){FlushMsgs;mp_before=Fs->data_heap->used_u8s;mp_mode=mode;mp_release=mp_stage=mp_frame_done=FALSE;mp_owner=Spawn(&UserCmdLine,NULL,"MouseView",-1,Fs,8192);TaskWait(mp_owner,TRUE);WinFocus(mp_owner);}',
  []),
 ('U0 '
  'MPBegin(){if(!MouseGet(&mp_x,&mp_y,&mp_buttons,&mp_packets))throw(\'NoMouse\',TRUE);mp_holder=Spawn(&MPHolder,NULL,"Mouse '
  'frame",-1,Fs,8192);while(!mp_stage)Yield;MPMark("MOUSE WAIT ready ");}',
  []),
 ('U0 MPPacket(){I64 '
  'p;while(TRUE){if(MouseGet(&mp_x,&mp_y,NULL,&p)&&p!=mp_packets)break;Yield;}MPTurn;MPMark("MOUSE WAIT '
  'packet ");}',
  []),
 ('U0 MPRelease(){mp_release=TRUE;while(TaskValidate(mp_holder))Yield;MPTurn;}', []),
 ('U0 '
  'MPBlue(){if(mp_mode==2){while(TRUE){if(MouseGet(&mp_x,&mp_y,&mp_buttons)&&mp_buttons&2)break;Yield;}MPRelease;MPMark("MOUSE '
  'WAIT frame ");}}',
  []),
 ('I64 MPFinish(I64 m){Bool '
  'ok=TRUE;while(sys_focus_task!=Fs)Yield;if(mp_mode==1)ok=Kill(mp_owner,TRUE,FALSE)&&!TaskValidate(mp_owner);if(ok)m|=4;MPRelease;if(mp_frame_done)m|=8;return '
  'm;}',
  []),
 ('I64 MPClean(I64 '
  'm){if(TaskValidate(mp_owner))Kill(mp_owner,TRUE,FALSE);MPTurn;FlushMsgs;if(!TaskValidate(mp_owner)&&sys_focus_task==Fs)m|=16;if(Fs->data_heap->used_u8s==mp_before)m|=32;if(NativeGraphicsStart)m|=64;return '
  'm;}',
  []),
 ('I64 MPRun(I64 mode){I64 '
  'm=0;MPStart(mode);MPBegin;if(mp_stage&&!mp_frame_done)m|=1;MPPacket;if(TaskValidate(mp_holder))m|=2;MPBlue;m=MPClean(MPFinish(m));MPMark("MOUSE '
  'WAIT return ");return m;}',
  []),
 ('MPRun(0);',
  ['127'],
  {'begin': 'MOUSE WAIT ready 0\n',
   'end': 'MOUSE WAIT return 0\n',
   'events': [{'mouse_to': [400, 300]},
              {'wait_log': 'MOUSE WAIT packet 0\n'},
              {'delay': 0.1},
              {'expect_rows': ['TempleOS i386', 'HolyC console', 'Task: MouseView', '', '> '],
               'label': 'no-overlay-through-held-frame'}],
   'exit_keys': ['ctrl', 'alt', 'n'],
   'final_canvas_color': 15,
   'final_rows': ['TempleOS i386', 'HolyC console', 'Task: MouseView', '', '> '],
   'initial_rows': ['TempleOS i386', 'HolyC console', 'Task: MouseView', '', '> '],
   'preserve_history': True,
   'return_pointer': [400, 300]}),
 ('MPRun(1);',
  ['127'],
  {'begin': 'MOUSE WAIT ready 1\n',
   'end': 'MOUSE WAIT return 1\n',
   'events': [{'mouse_to': [420, 310]},
              {'wait_log': 'MOUSE WAIT packet 1\n'},
              {'delay': 0.1},
              {'expect_rows': ['TempleOS i386', 'HolyC console', 'Task: MouseView', '', '> '],
               'label': 'no-overlay-through-held-frame'}],
   'exit_keys': ['ctrl', 'alt', 'n'],
   'final_canvas_color': 15,
   'final_rows': ['TempleOS i386', 'HolyC console', 'Task: MouseView', '', '> '],
   'initial_rows': ['TempleOS i386', 'HolyC console', 'Task: MouseView', '', '> '],
   'preserve_history': True,
   'return_pointer': [420, 310]}),
 ('MPRun(2);',
  ['127'],
  {'begin': 'MOUSE WAIT ready 2\n',
   'end': 'MOUSE WAIT return 2\n',
   'events': [{'mouse_to': [440, 320]},
              {'wait_log': 'MOUSE WAIT packet 2\n'},
              {'delay': 0.1},
              {'expect_rows': ['TempleOS i386', 'HolyC console', 'Task: MouseView', '', '> '],
               'label': 'no-overlay-through-held-frame'},
              {'down': True, 'mouse_button': 'right'},
              {'wait_log': 'MOUSE WAIT frame 2\n'},
              {'canvas_color': 1, 'expect_rows': [], 'label': 'new-frame-without-stale-terminal-rows'},
              {'down': False, 'mouse_button': 'right'}],
   'exit_keys': ['ctrl', 'alt', 'n'],
   'final_canvas_color': 1,
   'final_rows': [],
   'initial_rows': ['TempleOS i386', 'HolyC console', 'Task: MouseView', '', '> '],
   'preserve_history': True,
   'return_pointer': [440, 320]}),
 ('Bool MPInvalid(){U32 *saved=gr.text_base;Bool '
  'r;gr.text_base=NULL;try{r=NativeTextBasePresent;}catch{gr.text_base=saved;}gr.text_base=saved;return !r;}',
  []),
 ('MPInvalid;', ['1']),
 ('NativeGraphicsPresent();', ['1']),
 ('NativeTextBasePresent();', ['1']),
 ('6*7;', ['42'])]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('disk', type=Path)
    parser.add_argument('--out', type=Path, required=True)
    args = parser.parse_args()
    source, out = args.disk.resolve(), args.out.resolve()
    commands = list(COMMANDS)
    if out.exists():
        parser.error('Use a fresh output directory')
    sha = lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
    runner = ROOT/'tools/i386-kernel-input.py'
    pins = {str(p):sha(p) for p in [source, runner, ROOT/"Kernel/FontStd.HC", Path(__file__).resolve()]}
    out.mkdir(parents=True)
    working = out/'working.img'
    shutil.copyfile(source, working)
    report = dict(result='running', scope='Real PS/2 movement during yielding graphics: deferred terminal overlays, killed waiting terminal, stale backing invalidation, blue full-frame oracle, exact parent recovery and automatic whole-console restoration; not full desktop refresh',
                  input_sha256=pins, commands=commands)
    try:
        report['behavior'] = runpy.run_path(str(runner))['run_input'](
            working, out/'qemu', snapshot=False, ram_mib=64,
            cpu='486,-fpu', accel='tcg', qmp_stdio=True,
            startup_check={'status':'ok', 'answers':[], 'commands':commands,
                           'rejection_prefixes':('INPUT REJECT ',),
                           'command_timeout':60})
        report['result'] = 'pass'
    except Exception as exc:
        report.update(result='fail', error=str(exc))
        raise
    finally:
        report['inputs_unchanged'] = all(sha(Path(p)) == digest for p,digest in pins.items())
        if not report['inputs_unchanged']:
            report.update(result='fail', error='Native fixture inputs changed')
        (out/'result.json').write_text(json.dumps(report,indent=2)+'\n')
    if report['result']!='pass':
        raise ValueError(report['error'])


if __name__=='__main__':
    main()
