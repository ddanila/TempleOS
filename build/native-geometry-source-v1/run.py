import argparse
import hashlib
import json
from pathlib import Path
import runpy
import time

parser = argparse.ArgumentParser()
parser.add_argument('disk',type=Path)
parser.add_argument('--app', choices=('GrModels','ToTheFront','X-Caliber'), required=True)
parser.add_argument('--serial-visibility', action='store_true')
parser.add_argument('--split-fire', action='store_true')
parser.add_argument('--fix-indirect-head', action='store_true')
parser.add_argument('--original-wrap', action='store_true')
parser.add_argument('--ball-form', action='store_true')
parser.add_argument('--out',type=Path,required=True)
args = parser.parse_args()
if args.serial_visibility and args.app != 'ToTheFront':
    parser.error('--serial-visibility requires --app ToTheFront')
if args.split_fire and not args.serial_visibility:
    parser.error('--split-fire requires --serial-visibility')
if args.fix_indirect_head and not args.split_fire:
    parser.error('--fix-indirect-head requires --split-fire')
if args.original_wrap and not args.serial_visibility:
    parser.error('--original-wrap requires --serial-visibility')
if args.ball_form and args.app != 'GrModels':
    parser.error('--ball-form requires --app GrModels')
out = args.out.resolve()
out.mkdir()
extras={}
fire_units=[]
if args.app=='GrModels':
    source=Path('Adam/DolDoc/DocGr.HC').read_bytes()
    extras['/LightingChooser.HC']=source[
        source.index(b'public I64 PopUpColorLighting'):source.index(b'class CTransformForm')]
if args.app=='ToTheFront':
    source=Path('Adam/DolDoc/DocPopUp.HC').read_bytes()
    extras['/IntegerPrompt.HC']=source[
        source.index(b'public I64 PopUpGetI64'):source.index(b'public F64 PopUpGetF64')]
    if args.serial_visibility:
        app = Path('Apps/ToTheFront')
        visibility = (app/'TTFVis.HC').read_bytes()
        start = visibility.index(b'  I64 i,hi,k,cnt;', visibility.index(b'Bool VisRecalc('))
        end = visibility.index(b'  if (mode==VR_FRIENDLY_UNIT_DIED)', start)
        visibility = visibility[:start] + b'  I64 hi;\n  Bool res;\n  MPCtrl1 job;\n\n' + visibility[end:]
        visibility = visibility.replace(b'  cnt=mp_cnt; //Cores\n', b'', 1)
        start = visibility.index(b'  k=hi;', start)
        end = visibility.index(b'  if (mode==VR_UPDATE_FRIENDLY_UNIT)', start)
        visibility = visibility[:start] + b"""  job.mode=mode;
  job.tmpu=tmpu;
  job.lo=0;
  job.hi=hi;
  res=MPVisRecalc(&job);
""" + visibility[end:]
        start = visibility.index(b'  I64 i,hi,k,cnt;', visibility.index(b'U0 VisRecalcMap('))
        end = visibility.index(b'\n}', start)
        visibility = visibility[:start] + b"""  MPCtrl2 job;
  job.row=row;
  job.col=col;
  job.lo=0;
  job.hi=map_rows;
  MPVisRecalcMap(&job);""" + visibility[end:]
        extras['/TTFSerialVis.HC'] = visibility
        if args.original_wrap:
            math_source = Path('Adam/AMath.HC').read_bytes()
            extras['/TTFWrap.HC'] = math_source[
                math_source.index(b'public F64 Wrap('):
                math_source.index(b'#include "/Adam/DistSqrCore.HC"')]
        if args.split_fire:
            fire = (app/'TTFFire.HC').read_bytes()
            functions = (b'U0 AttackHeader(', b'F64 HitDamage(', b'Bool DamageDo(',
                         b'U0 IndirectAdd(', b'Bool BulletPlot(', b'U0 UnitDirectFire(',
                         b'Bool HexOccupy(', b'U0 IndirectResolveAll(')
            starts = [fire.index(function) for function in functions] + [len(fire)]
            for start, end in zip(starts, starts[1:]):
                name = fire[start:fire.index(b'(', start)].split()[-1].decode('ascii')
                path = f'/TTF{name}.HC'
                fire_units.append(path)
                source = fire[start:end]
                if args.fix_indirect_head and name == 'IndirectResolveAll':
                    source = source.replace(b'tmpi!=*indirect_head', b'tmpi!=&indirect_head')
                extras[path] = source
if args.app=='X-Caliber':
    extras['/ExtraVectors.HC']=Path('build/xcaliber-vector-load-v1/Vector.HC').read_bytes()
math=Path('Adam/Gr/GrMath.HC').read_bytes()
line=math[math.index(b'public Bool Line('):math.index(b'#help_index "Graphics/Math/3D Transformation"')]
sprite=Path('Adam/Gr/SpriteRecordsCore.HC').read_bytes()
sizes=sprite[:sprite.index(b'\n};')+4]
point=Path('Adam/Gr/GrPointClipCore.HC').read_bytes()
plot=point[point.index(b'public Bool GrPlot('):point.index(b'Bool GrPlot1(')]
peek=point[point.index(b'public I64 GrPeek('):]
coverage=Path('Adam/Gr/GrPixelCoverageCore.HC').read_bytes()
geometry=b"""#include "/Adam/Gr/Gr.HH"
#include "/Adam/Gr/GrBlotCore.HC"
#define GR_SCALE (1<<32)
#include "/Adam/Gr/MatrixRotationCore.HC"
"""
geometry+=coverage+b"\nBool IsPixCovered0(CTask *task,I64 x,I64 y) {return GrPixelCoveredCore(task,x,y);}\n"
geometry+=b"\n".join((line,sizes,plot,peek))
extras['/PublicGeometrySource.HC']=geometry
packer = runpy.run_path('tools/package-i386-native-image.py')
image = out/'working.img'
report = {'result':'running','package':packer['package'](args.disk,image,additions=extras)}
Guest = runpy.run_path('tools/test-i386-autocomplete-interaction.py')['Guest']
guest = Guest(image,out/'guest',True)
try:
    guest.wait('DONE native kernel startup\n')
    commands=['#include "C:/PublicGeometrySource.HC"']
    if args.app=='X-Caliber':
        commands.append('AdamFile("/Kernel/I386/NativeODE.HC",FALSE);')
    for path in ('/LightingChooser.HC', '/IntegerPrompt.HC', '/ExtraVectors.HC'):
        if path in extras:
            commands.append(f'#include "C:{path}"')
    if args.serial_visibility:
        if args.original_wrap:
            commands.append('#include "C:/TTFWrap.HC"')
        commands.append('Cd("C:/Apps/ToTheFront");')
        for unit in ('TTFGlbls', 'TTFLib', 'TTFInit', 'TTFVis', 'TTFFire',
                     'TTFMove', 'TTFDraw', 'ToTheFront'):
            path = '/TTFSerialVis.HC' if unit == 'TTFVis' else f'/Apps/ToTheFront/{unit}.HC'
            paths = fire_units if unit == 'TTFFire' and fire_units else [path]
            commands.extend(f'#include "C:{name}"' for name in paths)
    else:
        commands.append(f'#include "C:/Apps/{args.app}/Load.HC"')
    report['completed_commands'] = []
    for command in commands:
        report['command']=command
        guest.command(command)
        report['completed_commands'].append(command)
    guest.command('6*7;')
    report['fresh_result']=guest.result_pixels()
    report['result']='pass'
    if args.ball_form:
        report['result'] = 'observed'
        start = len(guest.collect())
        guest.type('BallGen;')
        guest.press('ret')
        guest.wait('COMPILER BREAK ready', start=start)
        time.sleep(2)
        guest.screenshot('ball-form')
        guest.press('esc')
        time.sleep(2)
        guest.screenshot('ball-form-escape')
        report['ball_form_trace'] = guest.collect()[start:]

except Exception as exc:
    report.update(result='fail',error=str(exc))
    raise
finally:
    guest.close()
    (out/'result.json').write_text(json.dumps(report,indent=2)+'\n')
