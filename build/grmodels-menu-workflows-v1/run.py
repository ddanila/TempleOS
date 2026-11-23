"""Follow the bundled GrModels menu and export the resulting document mesh."""
import argparse
import hashlib
import json
from pathlib import Path
import re
import runpy
import struct
import subprocess
import time

from PIL import Image, ImageOps


def wait_text(guest, probe, font, label, frame_name):
    deadline = time.monotonic() + 90
    path = guest.out / (frame_name + '.png')
    while time.monotonic() < deadline:
        guest.collect()
        guest.screenshot(frame_name)
        with Image.open(path) as frame:
            rgb = frame.convert('RGB')
            for pixels in (rgb.load(), ImageOps.invert(rgb).load()):
                for row in range(60):
                    for column in range(81-len(label)):
                        if probe['text_at'](pixels,font,label,column,row):
                            return column, row
        time.sleep(.5)
    raise TimeoutError(f'Missing {label!r} in {frame_name}')


def click(guest, address, target):
    pointer = guest.out/'pointer.bin'
    for _ in range(50):
        guest.call('pmemsave', val=address, size=16, filename=str(pointer))
        x,y = struct.unpack('<2q',pointer.read_bytes())
        if (x,y) == target:
            break
        guest.call('input-send-event', events=[
            {'type':'rel', 'data':{'axis':'x','value':target[0]-x}},
            {'type':'rel', 'data':{'axis':'y','value':target[1]-y}},
        ])
        time.sleep(.2)
    else:
        raise ValueError(f'Mouse could not reach {target}')
    for down in (True, False):
        guest.call('input-send-event', events=[
            {'type':'btn', 'data':{'down':down,'button':'left'}},
        ])
        time.sleep(.2)


def exercise(guest, model):
    log = guest.wait('MODELS pointer ', 120)
    pointer = int(re.search(r'MODELS pointer ([0-9A-F]+)\n',log)[1],16)
    probe = runpy.run_path('tools/check-i386-autocomplete-numeric-pixels.py')
    font = probe['font_bytes']()
    wait_text(guest,probe,font,b'Make a CSprite model.','menu')
    if model == 'man':
        # Move focus off Man before checking its unhighlighted label.
        guest.press('tab')
    button = b'Ball' if model == 'ball' else b'Man'
    col,row = wait_text(guest,probe,font,button,'menu-button')
    click(guest,pointer,(col*8+12,row*8+3))
    form_label = b'Longitude Faces' if model == 'ball' else b'Torso Length'
    wait_text(guest,probe,font,form_label,'form')
    guest.press('esc')
    swatches = (4,) if model == 'ball' else (1,2,4,3)
    for index, color in enumerate(swatches):
        # The first Man chooser has a Shirt heading. The later choosers
        # replace that heading as the original application prompts for colors.
        if model == 'man':
            label = (b'Shirt', b'Pants', b'Skin', b'Shoes')[index]
            wait_text(guest,probe,font,label,f'chooser-header-{index}')
        col,row = wait_text(guest,probe,font,b'Single-Sided Full-Range',f'chooser-{index}')
        click(guest,pointer,(col*8+56,(row+1+color)*8+3))
    wait_text(guest,probe,font,b'(y or n)','confirmation')
    guest.press('n')
    guest.wait('MODELS document mesh ready\n',60)
    data = (guest.out/'MenuMesh.bin').read_bytes()
    vertices, triangles = struct.unpack_from('<2i',data,1)
    colors = sorted({tri[0] for tri in struct.iter_unpack('<4i',data[9+12*vertices:-1])})
    if (data[0] != 24 or data[-1] or not vertices or not triangles or
        len(data) != 10+12*vertices+16*triangles or colors != sorted(swatches)):
        raise ValueError(f'Unexpected document mesh {vertices}, {triangles}, {colors}')
    return dict(vertices=vertices,triangles=triangles,colors=colors,
                sha256=hashlib.sha256(data).hexdigest())


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('model',choices=('ball','man'))
    parser.add_argument('--disk',type=Path)
    parser.add_argument('--out',type=Path,required=True)
    args = parser.parse_args()
    out = args.out.resolve()
    out.mkdir()
    native = bool(args.disk)
    drive = 'C' if native else 'T'
    observer = Path(__file__).with_name('Observe.HC').read_bytes()
    workflow = (observer + b'\nModelObserve;\n' +
                f'#include "{drive}:/Apps/GrModels/Run.HC"\n'.encode() +
                b'ModelCapture;\n')
    report = {'model':args.model, 'workflow_sha256':hashlib.sha256(workflow).hexdigest()}
    if native:
        image = out/'working.img'
        pack = runpy.run_path('tools/package-i386-native-image.py')['package']
        report['package'] = pack(args.disk,image,additions={'/ModelsProbe.HC':workflow})
    else:
        image = out/'original.iso'
        overlay = out/'overlay'
        files = runpy.run_path('tools/test-i386-timeclock-reference.py')['restore_reference'](overlay)
        report['application_sha256'] = {path:sha for path,sha in files.items()
                                        if path.startswith('Apps/GrModels/')}
        (overlay/'Once.HC').write_bytes(b'while(!Bt(&sys_run_level,RLf_ADAM_SERVER))Yield;\n'+workflow)
        subprocess.run(['python3','tools/build-iso.py','--overlay',str(overlay),
                        '--output',str(image)],check=True)
    Guest = runpy.run_path('tools/test-i386-autocomplete-interaction.py')['Guest']
    guest = Guest(image,out/'guest',native)
    try:
        if native:
            guest.wait('DONE native kernel startup\n')
            guest.type('#include "C:/ModelsProbe.HC"')
            guest.press('ret')
        report['mesh'] = exercise(guest,args.model)
        if native:
            guest.wait('COMMAND OK\n')
            guest.command('6*7;')
            report['fresh_arithmetic'] = guest.result_pixels()
        report['result'] = 'pass'
    except Exception as error:
        report.update(result='fail',error=str(error))
        raise
    finally:
        guest.close()
        (out/'result.json').write_text(json.dumps(report,indent=2)+'\n')


if __name__ == '__main__':
    main()
