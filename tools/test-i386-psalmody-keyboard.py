#!/usr/bin/env python3
"""Drive original/native Psalmody recording, deletion and abort with QEMU keys."""
import argparse
import hashlib
import json
from pathlib import Path
import re
import runpy
import struct
import subprocess
import time
import wave

ROOT=Path(__file__).resolve().parents[1]
NAMES=('notes.bin','deleted.bin','mask.bin')
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()


def verify_playback(wav, offset, output):
    with wave.open(str(wav), 'rb') as source:
        frame_bytes = source.getsampwidth()*source.getnchannels()
        header_bytes = wav.stat().st_size-source.getnframes()*frame_bytes
        source.setpos((offset-header_bytes)//frame_bytes)
        with wave.open(str(output), 'wb') as destination:
            destination.setparams(source.getparams())
            destination.writeframes(source.readframes(source.getnframes() - source.tell()))
    matcher = runpy.run_path(str(ROOT/'tools/test-i386-oh-great.py'))['pitches']
    return {**matcher(output, (523.25, 587.33)), 'wav_sha256': sha(output)}


def verify(records):
    notes,deleted,mask=records
    expected=[3,1,63,8,0,1,65,8,0,1,67,8,0]
    if notes!=struct.pack('<13q',*expected):raise ValueError('Recorded notes differ: '+repr(struct.unpack('<13q',notes)))
    if deleted!=struct.pack('<9q',2,*expected[1:9]):raise ValueError('Backspace survivors differ')
    if mask!=struct.pack('<q',63):raise ValueError('Caller restoration differs: '+repr(mask))

def main():
    ap=argparse.ArgumentParser(description=__doc__);ap.add_argument('disk',type=Path,nargs='?');ap.add_argument('--reference',type=Path);ap.add_argument('--out',type=Path,required=True)
    ap.add_argument('--playback',action='store_true',help='Play the two surviving notes and check speaker PCM')
    ap.add_argument('--save-reopen',action='store_true',help='Save a song and reopen it through the JukeBox')
    ap.add_argument('--startup-providers',action='store_true',help='Use the native desktop providers without fixture staging')
    ap.add_argument('--preview',action='store_true',help='Preview the saved song before reopening it')
    args=ap.parse_args();out=args.out.resolve()
    if args.preview and not args.save_reopen:ap.error('Preview requires --save-reopen')
    if out.exists():ap.error('Use a fresh output directory')
    if args.disk and not args.reference:ap.error('Native requires original reference')
    if args.startup_providers and not args.disk:ap.error('Startup providers require a native disk')
    fixture=ROOT/'tests/guest/i386-psalmody-keyboard/Contract.HC'
    paths=[Path(__file__).resolve(),fixture,ROOT/'docs/i386-compatibility-inventory.json',ROOT/'Kernel/FontStd.HC']+[ROOT/('tools/'+n) for n in ['test-i386-timeclock-reference.py','test-i386-autocomplete-interaction.py','test-i386-timeclock-welcome.py','build-iso.py','package-i386-native-image.py','build-i386-kernel.py']]
    if args.playback or args.preview:
        paths.append(ROOT/'tools/test-i386-oh-great.py')
    script=fixture.read_bytes()
    if args.save_reopen:
        persistence=fixture.with_name('Persistence.HC')
        paths += [persistence,ROOT/'build/grmodels-menu-workflows-v1/run.py',
                  ROOT/'tools/check-i386-autocomplete-numeric-pixels.py']
        script+=persistence.read_bytes()
    entry_command='PsalmodyPersistence;' if args.save_reopen else 'PsalmodyKeyboard;'
    if args.disk:
        gold=args.reference.resolve();info=json.loads((gold/'result.json').read_text())
        if info.get('result')!='pass' or not info.get('inputs_unchanged') or info.get('fixture_sha256')!=sha(fixture):raise ValueError('Matching original control required')
        if args.playback and not info.get('playback'):
            raise ValueError('A passing original playback control is required')
        if args.save_reopen and not info.get('persistence'):
            raise ValueError('A passing original persistence control is required')
        if args.preview and not info.get('preview'):
            raise ValueError('A passing original speaker preview control is required')
        paths += [args.disk.resolve(),gold/'result.json']+[gold/n for n in NAMES]
        if args.save_reopen:
            paths += [gold/'song.HC',gold/'reopened.bin']
    out.mkdir();pins={str(p):sha(p) for p in paths};g=None
    report=dict(result='running',fixture_sha256=sha(fixture),input_sha256=pins,
                scope='Psalmody keyboard recording, note deletion, caller restoration and optional playback PCM or save and reopen.')
    (out/'fixture.HC').write_bytes(script);(out/'runner-source.py').write_bytes(Path(__file__).read_bytes())
    try:
        if args.disk:
            pack=runpy.run_path(str(ROOT/'tools/package-i386-native-image.py'));before=pack['snapshot'](args.disk.read_bytes())[1]
            for entry in json.loads((ROOT/'docs/i386-compatibility-inventory.json').read_text())['entries']:
                name=entry['path']
                if not name.startswith('Apps/Psalmody/'):
                    continue
                allowed={entry['reference_sha256']}
                if name=='Apps/Psalmody/PsalmodyMain.HC':
                    # Also accept the reviewed keyboard-arrival timing port.
                    allowed.add('c0d0d1367005783450788fe39b29e8e9f0becec872341bad61948ea1b098c13e')
                if name=='Apps/Psalmody/JukeBox.HC':
                    # Cancellation remains an I64 until an entry is selected.
                    allowed.add('eb10cd26d31d582d92d2ed81da9435008ebbda84a17aa512938224779fb127ca')
                if name=='Apps/Psalmody/PsalmodyFile.HC':
                    # Also accept the reviewed song serialization port.
                    allowed.add('1b8f7babdfe87eab5e474474bb099b10b5c95c0812f03f96ed026c312823f612')
                if hashlib.sha256(before['/'+name][2]).hexdigest() not in allowed:
                    raise ValueError('Psalmody source differs: '+name)
            image=out/'working.img';report['packaging']=pack['package'](args.disk.resolve(),image,additions={'/Probe/PsalmodyKeyboard.HC':script})
        else:
            overlay=out/'overlay';overlay.mkdir();report['reference_sha256']=runpy.run_path(str(ROOT/'tools/test-i386-timeclock-reference.py'))['restore_reference'](overlay)
            setup=b'while(!Bt(&sys_run_level,RLf_ADAM_SERVER))Yield;\n'
            if args.save_reopen:
                setup+=b'Cd("B:/");DirMk("B:/PsmHome");HomeSet("B:/PsmHome");\n'
            (overlay/'Once.HC').write_bytes(setup+b'#include "T:/Apps/Psalmody/Load.HC"\n'+script+b'\n' + entry_command.encode() +b'\n')
            image=out/'original.iso';subprocess.run(['python3','tools/build-iso.py','--overlay',str(overlay),'--output',str(image)],cwd=ROOT,check=True)
        Guest=runpy.run_path(str(ROOT/'tools/test-i386-autocomplete-interaction.py'))['Guest']
        wav=out/'speaker.wav' if args.playback or args.preview else None
        g=Guest(image,out/'guest',bool(args.disk),audio_wav=wav)
        if args.disk:
            g.wait('DONE native kernel startup\n')
            providers = [] if args.startup_providers else [
                'AdamFile("C:/Adam/AutoComplete/MakeAC.HC",FALSE);',
                'AdamFile("C:/Adam/TaskSettings.HC",FALSE);',
                '#include "C:/Adam/Opt/Utils/Find.HC"',
                '#include "C:/Adam/God/GodExt.HC"',
                '#include "C:/Adam/God/GodBible.HC"',
                '#include "C:/Adam/God/HolySpirit.HC"',
                '#include "C:/Adam/God/GodSong.HC"',
            ]
            providers += [
                '#include "C:/Apps/Psalmody/Load.HC"',
                '#include "C:/Probe/PsalmodyKeyboard.HC"',
            ]
            report['startup_providers'] = args.startup_providers
            report['native_provider_commands'] = providers
            for command in providers:g.command(command)
            g.type(entry_command);g.press('ret')
        g.wait('PS ready\n');time.sleep(2);g.screenshot('ready');g.press('z');g.wait('PS recording\n',30)
        for i,key in enumerate(['h','j','k'],1):
            g.key(key,True);time.sleep(.4);g.key(key,False);g.wait(f'PS note {i}\n',30)
        g.screenshot('recorded');g.press('backspace');g.wait('PS deleted\n',30);g.screenshot('deleted')
        if args.playback:
            time.sleep(.5)
            offset=wav.stat().st_size
            if offset<=44:
                raise ValueError('Missing recorded speaker data before playback')
            g.key('ctrl',True)
            try:
                g.press('left')
            finally:
                g.key('ctrl',False)
            g.press('x')
            deadline=time.monotonic()+15
            last_change=time.monotonic()
            settled=offset
            while time.monotonic()<deadline:
                size=wav.stat().st_size
                if size!=settled:
                    settled=size
                    last_change=time.monotonic()
                elif size>offset and time.monotonic()-last_change>=.75:
                    break
                time.sleep(.05)
            else:
                raise ValueError('Playback did not emit audio and settle')
        if args.save_reopen:
            menu=runpy.run_path(str(ROOT/'build/grmodels-menu-workflows-v1/run.py'))
            wait_text=menu['wait_text']
            probe=runpy.run_path(str(ROOT/'tools/check-i386-autocomplete-numeric-pixels.py'))
            font=probe['font_bytes']()
            g.key('ctrl',True);g.press('a');g.key('ctrl',False)
            wait_text(g,probe,font,b'Tmp.HC.Z','save-form')
            g.press('esc')
            g.wait('PS saved\n',30)
            g.press(g.plain['.'])
            g.wait('PS cleared\n',30)
            pointer_log=g.wait('PS pointer ready\n',30)
            pointer=int(re.search(r'PS pointer ([0-9A-F]+)\n',pointer_log)[1],16)
            g.key('ctrl',True);g.press('o');g.key('ctrl',False)
            wait_text(g,probe,font,b'Sel a song and preview it.','open-help')
            col,row=wait_text(g,probe,font,b'OKAY','open-confirm')
            menu['click'](g,pointer,(col*8+12,row*8+3))
            _,header=wait_text(g,probe,font,b'to get your reward','open-chooser')
            col,row=wait_text(g,probe,font,b'Tmp','open-menu',first_row=header+1)
            if args.preview:
                preview_offset=wav.stat().st_size
                report['preview_start_byte']=preview_offset
                chooser_start=len(g.collect())
                menu['click'](g,pointer,(col*8+12,row*8+3))
                wait_text(g,probe,font,b'to get your reward','preview-chooser')
                g.wait('PS popup focused\n',45,chooser_start)
                deadline=time.monotonic()+35
                while wav.stat().st_size-preview_offset<180000:
                    if time.monotonic()>=deadline or g.p.poll() is not None:
                        raise ValueError('Missing speaker output from the song preview')
                    time.sleep(.05)
                g.screenshot('preview')
                g.key('shift',True)
                try:
                    g.press('esc')
                finally:
                    g.key('shift',False)
            else:
                g.press('esc')
            g.wait('PS reopened\n',30)
        g.key('shift',True);g.press('esc');g.key('shift',False);g.wait('PS done\n',30)
        records=[(g.out/n).read_bytes() for n in NAMES]
        for n,v in zip(NAMES,records):(out/n).write_bytes(v)
        verify(records)
        if args.save_reopen:
            g.wait('PS saved bytes\n',30)
            for name in ('song.HC','reopened.bin'):
                (out/name).write_bytes((g.out/name).read_bytes())
            if (out/'reopened.bin').read_bytes()!=records[1]:
                raise ValueError('Reopened notes differ from the saved notes')
            if args.disk and (out/'song.HC').read_bytes()!=(gold/'song.HC').read_bytes():
                raise ValueError('Saved song bytes differ from the original')
            report['persistence']={'song_sha256':sha(out/'song.HC'),'reopened_notes':2}
        if args.disk:
            if records!=[(gold/n).read_bytes() for n in NAMES]:raise ValueError('Original vectors differ')
            g.wait('COMMAND OK\n',start=g.collect().index('INPUT LINE '+entry_command));g.command('6*7;');g.result_pixels()
        g.close();g=None
        if args.preview:
            report['preview']=verify_playback(wav,preview_offset,out/'preview.wav')
        if args.playback:
            report['playback']=verify_playback(wav,offset,out/'playback.wav')
        if args.disk:
            after=pack['snapshot'](image.read_bytes())[1];changed={n for n in set(before)|set(after) if before.get(n)!=after.get(n)}
            expected_changes={'/Probe/PsalmodyKeyboard.HC'}
            if args.save_reopen:
                songs={name for name in changed if name.endswith('/Psalmody/Tmp.HC.Z') and name not in before}
                if len(songs)!=1:
                    raise ValueError('Expected one new saved Psalmody song')
                expected_changes|=songs
                report['persistence']['saved_path']=songs.pop()
            if changed!=expected_changes:raise ValueError('Unexpected file changes: '+repr(changed))
            report['preserved_files']=len(before);report['filesystem']=runpy.run_path(str(ROOT/'tools/build-i386-kernel.py'))['verify_mutated_volume'](image)
        report.update(result='pass',mask=63,notes=list(struct.unpack('<13q',records[0])))
    except Exception as exc:report.update(result='fail',error=str(exc));raise
    finally:
        if g:g.close()
        report['inputs_unchanged']=all(p.is_file() and sha(p)==pins[str(p)] for p in paths)
        if not report['inputs_unchanged']:report.update(result='fail',error='Inputs changed')
        (out/'result.json').write_text(json.dumps(report,indent=2)+'\n')

if __name__=='__main__':main()
