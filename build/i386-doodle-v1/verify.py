"""Verify the paired Doodle stroke and cleanup frames."""
from pathlib import Path
import hashlib
import json

from PIL import Image

root=Path(__file__).resolve().parent
source=root.parents[1]/'Demo/Graphics/Doodle.HC'
digest=hashlib.sha256(source.read_bytes()).hexdigest()
reports={mode:json.loads((root/mode/'result.json').read_text()) for mode in ('original','native')}
if any(r['result']!='pass' or r['demo_sha256']!=digest for r in reports.values()):
    raise ValueError('Launch evidence differs from the bundled source')


def stroke_mask(mode,frame,box,color):
    path=root/mode/'guest'/(frame+'.png')
    with Image.open(path) as image:
        pixels=image.convert('RGB').crop(box).get_flattened_data()
    return {index for index,pixel in enumerate(pixels) if pixel==color}


strokes={}
for stroke,box,color in [('black',(90,155,272,244),(0,0,0)),('red',(308,234,535,335),(168,0,0))]:
    key=stroke+'_drag'
    if reports['original'][key]!=reports['native'][key]:
        raise ValueError(f'Physical drag endpoints differ for {stroke}')
    masks=[]
    for mode,receipt in reports.items():
        mask=stroke_mask(mode,stroke,box,color)
        if (len(mask)<150 or len(mask)!=receipt[stroke+'_pixels'] or
                stroke_mask(mode,'start',box,color) or stroke_mask(mode,'cleared',box,color)):
            raise ValueError(f'Incorrect stroke or cleanup for {mode} {stroke}')
        if stroke=='black' and stroke_mask(mode,'red',box,color)!=mask:
            raise ValueError(f'Choosing red changed the black line in {mode}')
        masks.append(mask)
    if masks[0]!=masks[1]:
        raise ValueError(f'Original and native {stroke} masks differ')
    strokes[stroke]=dict(endpoints=reports['native'][key],matching_pixels=len(masks[0]))
print(json.dumps(dict(result='pass',demo_sha256=digest,strokes=strokes,
                      both_strokes_cleared=True,fresh_arithmetic=reports['native']['fresh_arithmetic']),indent=2))
