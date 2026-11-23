import hashlib
import json
from pathlib import Path
import runpy
import sys
from PIL import Image, ImageChops

out = Path(sys.argv[1]).resolve()
out.mkdir()
baseline, candidate = map(Path, sys.argv[2:4])
contract = Path('tools/test-i386-persistent-window.py')
runner = Path('tools/test-i386-autocomplete-interaction.py')
packer = Path('tools/package-i386-native-image.py')
sha = lambda path: hashlib.sha256(path.read_bytes()).hexdigest()
pins = {str(p):sha(p) for p in (baseline, candidate, contract, runner, packer, Path(__file__))}
commands = runpy.run_path(str(contract))['COMMANDS']
raw_cases = """U0 PGRawClobber()
{
  I64 old_col=text.raw_col;
  text.raw_col=810;
  RawPutChar('X');
  text.raw_col=old_col;
}
U0 PGPalette(Bool clear)
{
  I64 i;
  for(i=0;i<1024;i++)
    if(clear)gr.dc->body[640*460+i]=TRANSPARENT;
    else gr.dc->body[640*460+i]=(i^(i>>4))&15;
}
U0 PGForceClobber()
{
  U8 *address=0xA0000+80*80+10;
  OutU8(0x3C4,2);
  OutU8(0x3C5,15);
  *address=0xFF;
  VGAFlush;
}
"""
body = '\n'.join(row[0] for row in commands[:-2])+'\n'
body = body.replace('PGSecond;PGWait', 'PGRawClobber;PGWait("PG R\\n");'
                    'PGForceClobber;PGWait("PG F\\n");'
                    'PGPalette(FALSE);PGWait("PG P\\n");PGPalette(TRUE);PGWait("PG Q\\n");PGSecond;PGWait')
fixture = (raw_cases+body).encode()
(out/'PersistentRow.HC').write_bytes(fixture)
Guest = runpy.run_path(str(runner))['Guest']
pack = runpy.run_path(str(packer))
report = dict(result='running',input_sha256=pins,scope='Native full versus changed-row VGA uploads through direct bitmap changes, final hook layering and return to ordinary output. Eight exact rasters, including raw output restoration, forced VGA flush, and a mixed sixteen-color pattern, followed by fresh arithmetic.')
guest = None
try:
    for label, disk in [('full',baseline),('dirty',candidate)]:
        case=out/label
        case.mkdir()
        image=case/'working.img'
        pack['package'](disk,image,additions={'/Probe/PersistentRow.HC':fixture})
        guest = Guest(image,case/'guest',True)
        guest.wait('DONE native kernel startup\n')
        guest.command('#include "C:/Probe/PersistentRow.HC"')
        start=len(guest.collect())
        guest.type('PGView;')
        guest.press('ret')
        for phase in 'ARFPQBCD':
            guest.wait(f'PG {phase}\n',30,start=start)
            guest.screenshot(phase)
            guest.press('spc' if phase!='D' else 'esc')
        guest.wait('PG end\n',30,start=start)
        guest.wait('COMMAND OK\n',30,start=start)
        guest.command('6*7;')
        guest.result_pixels()
        guest.close()
        guest=None
    hashes={}
    for phase in 'ARFPQBCD':
        oracle=out/'full/guest'/f'{phase}.png'
        observed=out/'dirty/guest'/f'{phase}.png'
        original=Image.open(oracle).convert('RGB')
        actual=Image.open(observed).convert('RGB')
        box=ImageChops.difference(original,actual).getbbox()
        if box:
            raise ValueError(f'Raster {phase} differs at {box}')
        hashes[phase]={'raster_sha256':hashlib.sha256(actual.tobytes()).hexdigest(),
                       'test_pixel':actual.getpixel((80,80))}
    assert [hashes[stage]['test_pixel'] for stage in 'ABC']==[(168,0,0),(0,168,0),(0,0,168)]
    palette=Image.open(out/'dirty/guest/P.png').convert('RGB')
    palette_colors={palette.getpixel((x,460)) for x in range(32)}
    assert len(palette_colors)==16
    assert len({hashes[stage]['raster_sha256'] for stage in 'ARFQ'}) == 1
    assert hashes['D']['test_pixel'] not in [hashes[stage]['test_pixel'] for stage in 'ABC']
    report.update(result='pass',frames=hashes,palette_colors=len(palette_colors))
except Exception as exc:
    report.update(result='fail',error=str(exc))
    raise
finally:
    if guest:
        guest.close()
    report['inputs_unchanged']=all(sha(Path(path))==digest for path,digest in pins.items())
    (out/'result.json').write_text(json.dumps(report,indent=2)+'\n')
