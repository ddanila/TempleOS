"""Compare paired Speedline strokes in their steady-speed center sections."""
import hashlib
import json
from pathlib import Path

from PIL import Image

out=Path(__file__).resolve().parent
source=out.parents[1]/'Demo/Graphics/Speedline.HC'
digest=hashlib.sha256(source.read_bytes()).hexdigest()
modes=('original','native')
receipts={mode:json.loads((out/mode/'result.json').read_text()) for mode in modes}
if any(r['result']!='pass' or r['demo_sha256']!=digest for r in receipts.values()):
    raise ValueError('Launch evidence differs from the bundled Speedline demo')


def mask(mode,frame,box,color):
    with Image.open(out/mode/'guest'/(frame+'.png')) as image:
        data=image.convert('RGB').crop(box).get_flattened_data()
    return {index for index,pixel in enumerate(data) if pixel==color}


strokes={}
regions=(('slow',(140,130,220,210),(0,0,0)),('fast',(140,205,220,285),(0,0,0)),
         ('red',(360,280,440,365),(168,0,0)))
for stroke,box,color in regions:
    width=box[2]-box[0]
    masks=[]
    for mode in modes:
        observed=mask(mode,stroke,box,color)
        if (len(observed)!=receipts[mode][stroke+'_pixels'] or
                mask(mode,'start',box,color) or mask(mode,'cleared',box,color)):
            raise ValueError(f'Incorrect stroke or cleanup in {mode}')
        if stroke!='red' and mask(mode,'red',box,color)!=observed:
            raise ValueError(f'Changing color erased the {stroke} stroke in {mode}')
        masks.append(observed)
    original,native=masks
    if stroke=='red':
        if not original or len(original ^ native)>width or not (original<=native or native<=original):
            raise ValueError('Red stroke varies by more than one row')
    elif original!=native:
        raise ValueError(f'Original and native {stroke} masks differ')
    rows=[[sum((y*width+x) in pixels for y in range(box[3]-box[1]))
           for x in range(width)] for pixels in masks]
    strokes[stroke]=dict(original_pixels=len(original),native_pixels=len(native),
        matching_pixels=len(original & native),original_thickness=[min(rows[0]),max(rows[0])],
        native_thickness=[min(rows[1]),max(rows[1])])
if strokes['fast']['matching_pixels']<=strokes['slow']['matching_pixels']+160:
    raise ValueError('Faster drag did not increase stroke thickness')
print(json.dumps(dict(result='pass',demo_sha256=digest,strokes=strokes,
                      all_strokes_cleared=True,fresh_arithmetic=receipts['native']['fresh_arithmetic']),indent=2))
