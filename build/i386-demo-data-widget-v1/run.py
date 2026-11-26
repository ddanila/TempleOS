"""Compare the live numeric and string fields in the bundled DolDoc Data demo."""
import argparse
from concurrent.futures import ThreadPoolExecutor
import hashlib
import json
from pathlib import Path
import runpy
import time
import shutil

from PIL import Image


SOURCE = Path('Demo/DolDoc/Data.HC')


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def number(frame, row, column, font):
    digits = {font[ch]: chr(ch) for ch in b' 0123456789-'}
    with Image.open(frame) as image:
        pixels = image.convert('RGB').load()
        text = ''
        for col in range(column, column + 7):
            mask = tuple(sum((pixels[col*8+x,row*8+y] != (255,255,255)) << x
                             for x in range(8)) for y in range(8))
            text += digits.get(mask,'?')
    return int(text)


def send(guest, native, text):
    if native:
        guest.command(text)
    else:
        guest.type(text)
        guest.press('ret')
        time.sleep(1)


def capture(guest_type, vision, font, image, out, native, edit, editor_key, physical):
    guest = guest_type(image,out,native,reference_cpus=1)
    try:
        guest.wait('DONE native kernel startup\n' if native else 'DEMO BATCH READY\n')
        send(guest,native,'WinBorder;WinMax;DocClear;')
        drive = 'C' if native else 'T'
        start = len(guest.collect())
        send(guest,native,f'ExeFile("{drive}:/{SOURCE}");')
        if 'INPUT REJECT ' in guest.collect()[start:]:
            raise ValueError(guest.collect()[start:][-1800:])
        samples = []
        for count in range(3):
            time.sleep(.5)
            name = f'data-{count}'
            guest.screenshot(name)
            frame = out/f'{name}.png'
            positions = vision['matches'](frame,'Str:Terry',font,first_row=0)
            if len(positions)!=1:
                raise ValueError(f'Missing or duplicated string field: {positions}')
            col,row = positions[0]
            samples.append(dict(value=number(frame,row-1,col,font),sha256=sha(frame),
                                string_cell=[col,row]))
        if len({sample['value'] for sample in samples})<3:
            raise ValueError('The numeric data field did not refresh')
        result = dict(result='pass',samples=samples)
        if edit:
            send(guest,native,'U0 DWLog(U8*s){while(*s)OutU8(0xE9,*s++);}')
            send(guest,native,f'MsSet({(col+4)*8+2},{row*8+4});')
            for down in (True,False):
                guest.call('input-send-event',events=[dict(type='btn',data=dict(button='left',down=down))])
                time.sleep(.1)
            guest.press('insert')
            guest.type('B')
            time.sleep(1)
            guest.screenshot('edited')
            edited = out/'edited.png'
            if not vision['matches'](edited,'Str:Berry',font,first_row=0):
                raise ValueError('Overstrike did not replace the first character of Terry')
            guest.press('end')
            start = len(guest.collect())
            send(guest,native,'if(!StrCmp(buf,"Berry"))DWLog("DATA WRITEBACK PASS\\n");')
            guest.wait('DATA WRITEBACK PASS\n',timeout=10,start=start)
            result['edit'] = dict(value='Berry',sha256=sha(edited),writeback=True)
        if editor_key or physical:
            send(guest,native,'U0 DWLog(U8*s){while(*s)OutU8(0xE9,*s++);}')
            send(guest,native,'CDocEntry *DWField(CDoc*d){CDocEntry*e=d->head.next;while(e!=d && e->data!=buf)e=e->next;return e;}')
            if physical:
                send(guest,native,'U0 DWOpen(){CDoc*d=DocPut;CDocEntry*e=DWField(d);if(e==d)return;d->cur_entry=e;d->cur_col=e->min_col;DWLog("DATA EDITOR READY\\n");DocEd(d,DOF_DONT_HOME);if(!StrCmp(buf,"Tarry"))DWLog("DATA WRITEBACK PASS\\n");DocBottom(d);}')
                start = len(guest.collect())
                guest.type('DWOpen;')
                guest.press('ret')
                guest.wait('DATA EDITOR READY\n',timeout=15,start=start)
                time.sleep(2)
                guest.screenshot('editor-open')
                guest.press('right')
                guest.press('insert')
                guest.press('a')
                time.sleep(1)
                guest.screenshot('physical-edit')
                guest.press('esc')
                if native:
                    guest.wait('COMMAND OK\n',timeout=20,start=start)
                guest.wait('DATA WRITEBACK PASS\n',timeout=10,start=start)
                time.sleep(1)
                guest.screenshot('physical-closed')
                frame = out/'physical-closed.png'
                if not vision['matches'](frame,'Str:Tarry',font,first_row=0):
                    raise ValueError('Physical edit was not rendered after the editor closed')
                result['physical_edit'] = dict(value='Tarry',sha256=sha(frame),writeback=True)
                if native:
                    guest.press('end')
            else:
                send(guest,native,'U0 DWEdit(){CDoc*d=DocPut;CDocEntry*e=DWField(d);Bool os=Bt(&d->flags,DOCf_OVERSTRIKE);if(e==d)return;d->cur_entry=e;d->cur_col=e->min_col;if(!os)DocPutKey(d,0,SC_INS);DocPutKey(d,66);if(!os)DocPutKey(d,0,SC_INS);DocBottom(d);}')
                send(guest,native,'DWEdit;')
                start = len(guest.collect())
                send(guest,native,'if(!StrCmp(buf,"Berry"))DWLog("DATA WRITEBACK PASS\\n");')
                guest.wait('DATA WRITEBACK PASS\n',timeout=10,start=start)
                guest.screenshot('editor-key')
                frame = out/'editor-key.png'
                if not vision['matches'](frame,'Str:Berry',font,first_row=0):
                    raise ValueError('The edited backing value was not rendered')
                result['editor_key'] = dict(value='Berry',sha256=sha(frame),writeback=True)
        if native:
            guest.command('6*7;')
            result['fresh_result']=guest.result_pixels()
        return result
    finally:
        guest.close()


def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('original_iso',type=Path)
    parser.add_argument('native_image',type=Path)
    parser.add_argument('--out',required=True,type=Path)
    edit_mode=parser.add_mutually_exclusive_group()
    edit_mode.add_argument('--edit',action='store_true')
    edit_mode.add_argument('--editor-key',action='store_true')
    edit_mode.add_argument('--editor-physical',action='store_true')
    args=parser.parse_args()
    out=args.out.resolve()
    out.mkdir()
    original,native=(path.resolve() for path in (args.original_iso,args.native_image))
    font_path=Path('Kernel/FontStd.HC')
    pins={str(path):sha(path) for path in (original,native,SOURCE.resolve(),font_path.resolve())}
    disk=out/'working.img'
    shutil.copyfile(native,disk)
    guest=runpy.run_path('tools/test-i386-autocomplete-interaction.py')['Guest']
    vision=runpy.run_path('build/i386-demo-define-v1/qualify.py')
    font=vision['glyphs'](font_path)
    results={}
    with ThreadPoolExecutor(max_workers=2) as pool:
        runs={side:pool.submit(capture,guest,vision,font,image,out/side,side=='native',args.edit,args.editor_key,args.editor_physical)
              for side,image in (('original',original),('native',disk))}
        for side,future in runs.items():
            try:
                results[side]=future.result()
            except (RuntimeError,ValueError,TimeoutError) as error:
                results[side]=dict(result='fail',error=str(error))
    unchanged=all(sha(Path(path))==digest for path,digest in pins.items())
    passed=unchanged and all(run['result']=='pass' for run in results.values())
    (out/'result.json').write_text(json.dumps(dict(result='pass' if passed else 'fail',
                                               input_sha256=pins,inputs_unchanged=unchanged,runs=results),indent=2)+'\n')
    if not passed:
        raise SystemExit(1)


if __name__=='__main__':
    main()
