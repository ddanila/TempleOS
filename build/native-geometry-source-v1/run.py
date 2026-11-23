import argparse
import hashlib
import json
from pathlib import Path
import runpy
import struct
import time

parser = argparse.ArgumentParser()
parser.add_argument('disk',type=Path)
parser.add_argument('--app', choices=('GrModels','ToTheFront','X-Caliber'), required=True)
parser.add_argument('--serial-visibility', action='store_true')
parser.add_argument('--xcaliber-refresh-state', action='store_true')
parser.add_argument('--userspace-irqchip', action='store_true')
parser.add_argument('--xcaliber-loop-trace', action='store_true')
parser.add_argument('--xcaliber-no-fire', action='store_true')
parser.add_argument('--xcaliber-input-trace', action='store_true')
parser.add_argument('--xcaliber-play', action='store_true')
parser.add_argument('--xcaliber-desktop', action='store_true')
parser.add_argument('--xcaliber-frequency', action='store_true')
parser.add_argument('--xcaliber-square', action='store_true')
parser.add_argument('--split-xcaliber', action='store_true')
parser.add_argument('--split-fire', action='store_true')
parser.add_argument('--fix-indirect-head', action='store_true')
parser.add_argument('--original-wrap', action='store_true')
parser.add_argument('--ball-form', action='store_true')
parser.add_argument('--ball-mesh', action='store_true')
parser.add_argument('--vertex-trace', action='store_true')
parser.add_argument('--wide-product', action='store_true')
parser.add_argument('--original-curves', action='store_true')
parser.add_argument('--original-range', action='store_true')
parser.add_argument('--visibility-fixture', action='store_true')
parser.add_argument('--original-key-poll', action='store_true')
parser.add_argument('--original-task-settings', action='store_true')
parser.add_argument('--human-match', action='store_true')
parser.add_argument('--combined-loader', action='store_true')
parser.add_argument('--out',type=Path,required=True)
args = parser.parse_args()
if args.xcaliber_refresh_state and not args.xcaliber_loop_trace:
    parser.error('--xcaliber-refresh-state requires --xcaliber-loop-trace')
if args.xcaliber_loop_trace and not args.xcaliber_input_trace:
    parser.error('--xcaliber-loop-trace requires --xcaliber-input-trace')
if args.xcaliber_no_fire and not args.xcaliber_play:
    parser.error('--xcaliber-no-fire requires --xcaliber-play')
if args.xcaliber_input_trace and not args.xcaliber_play:
    parser.error('--xcaliber-input-trace requires --xcaliber-play')
if args.xcaliber_play and not args.xcaliber_desktop:
    parser.error('--xcaliber-play requires --xcaliber-desktop')
if args.xcaliber_desktop and not args.split_xcaliber:
    parser.error('--xcaliber-desktop requires --split-xcaliber')
if args.xcaliber_frequency and not args.split_xcaliber:
    parser.error('--xcaliber-frequency requires --split-xcaliber')
if args.xcaliber_square and not args.split_xcaliber:
    parser.error('--xcaliber-square requires --split-xcaliber')
if args.split_xcaliber and args.app != 'X-Caliber':
    parser.error('--split-xcaliber requires --app X-Caliber')
if args.serial_visibility and args.app != 'ToTheFront':
    parser.error('--serial-visibility requires --app ToTheFront')
if args.split_fire and not args.serial_visibility:
    parser.error('--split-fire requires --serial-visibility')
if args.fix_indirect_head and not args.split_fire:
    parser.error('--fix-indirect-head requires --split-fire')
if args.original_wrap and not args.serial_visibility:
    parser.error('--original-wrap requires --serial-visibility')
if (args.ball_form or args.ball_mesh) and args.app != 'GrModels':
    parser.error('--ball-form and --ball-mesh require --app GrModels')
if args.vertex_trace and not args.ball_mesh:
    parser.error('--vertex-trace requires --ball-mesh')
if args.wide_product and not args.vertex_trace:
    parser.error('--wide-product requires --vertex-trace')
if args.original_curves and not args.serial_visibility:
    parser.error('--original-curves requires --serial-visibility')
if args.original_range and not args.serial_visibility:
    parser.error('--original-range requires --serial-visibility')
if args.visibility_fixture and not args.serial_visibility:
    parser.error('--visibility-fixture requires --serial-visibility')
if args.original_key_poll and not args.serial_visibility:
    parser.error('--original-key-poll requires --serial-visibility')
if args.original_task_settings and not args.serial_visibility:
    parser.error('--original-task-settings requires --serial-visibility')
if args.human_match and (not args.original_task_settings or args.visibility_fixture):
    parser.error('--human-match needs the full ToTheFront loader with task settings')
if args.combined_loader and (args.app != 'ToTheFront' or args.visibility_fixture or
        not all((args.serial_visibility, args.split_fire, args.fix_indirect_head,
                 args.original_wrap, args.original_curves, args.original_range,
                 args.original_key_poll, args.original_task_settings))):
    parser.error('--combined-loader requires all ToTheFront loader dependencies')
out = args.out.resolve()
out.mkdir()
extras={}
fire_units=[]
ball_ui = Path('build/grmodels-ball-reference-v1')
if args.app=='GrModels':
    if args.ball_mesh:
        fixture = (ball_ui/'Interactive.HC').read_bytes()
        if args.vertex_trace:
            trace = runpy.run_path(str(ball_ui/'vertex_trace.py'))
            source = Path('Apps/GrModels/BallGen.HC').read_bytes()
            if args.wide_product:
                source = trace['widen_products'](source, (ball_ui/'WideProduct.HC').read_bytes())
            extras['/BallGenTrace.HC'] = trace['instrument'](source)
            fixture = trace['observe'](fixture)
        extras['/BallUI.HC'] = fixture
    source=Path('Adam/DolDoc/DocGr.HC').read_bytes()
    extras['/LightingChooser.HC']=source[
        source.index(b'public I64 PopUpColorLighting'):source.index(b'class CTransformForm')]
if args.app=='ToTheFront':
    source=Path('Adam/DolDoc/DocPopUp.HC').read_bytes()
    extras['/IntegerPrompt.HC']=source[
        source.index(b'public I64 PopUpGetI64'):source.index(b'public F64 PopUpGetF64')]
    if args.original_range:
        extras['/TTFRange.HC'] = source[
            source.index(b'public F64 PopUpRangeF64('):source.index(b'public F64 PopUpRangeF64Exp(')]
    if args.original_key_poll:
        message_source = Path('Kernel/SerialDev/Message.HC').read_bytes()
        extras['/TTFKeyPoll.HC'] = message_source[
            message_source.index(b'I64 ScanChar()'):message_source.index(b'#include "/Kernel/KeyScanCore.HC"')]
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
        if args.visibility_fixture:
            extras['/TTFVisibility.HC'] = Path('build/tothefront-original-v1/Visibility.HC').read_bytes()
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
    if args.xcaliber_play:
        extras['/XCProbe.HC'] = Path('build/xcaliber-reference-v1/Probe.HC').read_bytes()
    if args.xcaliber_frequency:
        misc = Path('Kernel/KMisc.HC').read_bytes()
        extras['/XCFrequency.HC'] = misc[misc.index(b'I8 Freq2Ona('):
                                          misc.index(b'#include "/Kernel/SoundCaptureCore.HC"')]
    if args.split_xcaliber:
        source = Path('Apps/X-Caliber/X-Caliber.HC').read_bytes()
        text, separator, assets = source.partition(b'\0')
        if not separator:
            raise ValueError('X-Caliber is missing its DolDoc binary records')
        if args.xcaliber_square:
            square = b'd=250000*tons/d`2;'
            if text.count(square) != 1:
                raise ValueError('Expected one X-Caliber explosion square')
            text = text.replace(square, b'd=250000*tons/Sqr(d);')
        declarations = (b'U0 MissileNew(', b'Ship *ShipNew(', b'U0 MissileDel(',
                        b'U0 DrawIt(', b'U0 Explosion(', b'Ship TargetGet(', b'U0 MyDerivative(',
                        b'U0 CheckDamage(', b'U0 SolarFlares(', b'U0 XCaliber(')
        boundaries = [0, *(text.index(name) for name in declarations), len(text)]
        xcaliber_units = []
        for index, (start, end) in enumerate(zip(boundaries, boundaries[1:])):
            path = f'/Apps/X-Caliber/Probe{index}.HC'
            unit = text[start:end]
            if args.xcaliber_input_trace and unit.startswith(b'U0 XCaliber('):
                trace = runpy.run_path('build/xcaliber-reference-v1/input_trace.py')
                unit = trace['instrument'](unit, loop=args.xcaliber_loop_trace,
                                           refresh=args.xcaliber_refresh_state)
            extras[path] = unit + separator + assets
            xcaliber_units.append(path)
math=Path('Adam/Gr/GrMath.HC').read_bytes()
if args.original_curves:
    sound_source = Path('Adam/Snd/SndMath.HC').read_bytes()
    saw = sound_source[sound_source.index(b'public F64 Saw('):sound_source.index(b'public F64 FullSaw(')]
    walkers = math[math.index(b'#define GR_SCALE1_BITS'):math.index(b'public Bool RegPoly(')]
    curves = Path('Adam/Gr/GrCurves3Core.HC').read_bytes()
    extras['/TTFCurves.HC'] = b'\n'.join((
        b'#include "/Adam/PolarCore.HC"', saw, walkers,
        curves[:curves.index(b'public Bool GrRegPoly3(')]))
sprite=Path('Adam/Gr/SpriteRecordsCore.HC').read_bytes()
sizes=sprite[:sprite.index(b'\n};')+4]
geometry=b"""#include "/Kernel/I386/NativeTTFGeometry.HC"
#define GR_SCALE (1<<32)
#include "/Adam/Gr/MatrixRotationCore.HC"
"""
geometry+=sizes
extras['/PublicGeometrySource.HC']=geometry
if args.combined_loader:
    app = '/Apps/ToTheFront'
    load = [
        '#help_index "Games"',
        'Cd(__DIR__);;',
        '#include "/PublicGeometrySource.HC"',
        '#include "/IntegerPrompt.HC"',
        '#include "/TTFWrap.HC"',
        '#include "TTFGlbls"',
        '#include "TTFLib"',
        '#include "TTFInit"',
        '#include "/TTFSerialVis.HC"',
        *(f'#include "{path}"' for path in fire_units),
        '#include "TTFMove"',
        '#include "/TTFCurves.HC"',
        '#include "TTFDraw"',
        '#include "/TTFRange.HC"',
        '#include "/TTFKeyPoll.HC"',
        'AdamFile("/Adam/AutoComplete/MakeAC.HC",FALSE);;',
        'AdamFile("/Adam/TaskSettings.HC",FALSE);;',
        '#include "ToTheFront"',
        '#help_index ""',
    ]
    extras[f'{app}/NativeLoadProbe.HC'] = ('\n'.join(load) + '\n').encode('ascii')
packer = runpy.run_path('tools/package-i386-native-image.py')
image = out/'working.img'
report = {'result':'running','package':packer['package'](args.disk,image,additions=extras)}
Guest = runpy.run_path('tools/test-i386-autocomplete-interaction.py')['Guest']
machine = 'pc,kernel-irqchip=off' if args.userspace_irqchip else 'pc'
report['machine'] = machine
guest = Guest(image, out/'guest', True, native_machine=machine)
try:
    guest.wait('DONE native kernel startup\n')
    commands=['#include "C:/PublicGeometrySource.HC"']
    if args.app=='X-Caliber':
        commands.append('AdamFile("/Kernel/I386/NativeODE.HC",FALSE);')
    for path in ('/LightingChooser.HC', '/IntegerPrompt.HC', '/ExtraVectors.HC', '/XCFrequency.HC'):
        if path in extras:
            commands.append(f'#include "C:{path}"')
    if args.serial_visibility:
        if args.original_wrap:
            commands.append('#include "C:/TTFWrap.HC"')
        commands.append('Cd("C:/Apps/ToTheFront");')
        for unit in ('TTFGlbls', 'TTFLib', 'TTFInit', 'TTFVis', 'TTFFire',
                     'TTFMove', 'TTFDraw', 'ToTheFront'):
            path = '/TTFSerialVis.HC' if unit == 'TTFVis' else f'/Apps/ToTheFront/{unit}.HC'
            if unit == 'TTFDraw' and args.original_curves:
                commands.append('#include "C:/TTFCurves.HC"')
            if unit == 'ToTheFront' and args.original_range:
                commands.append('#include "C:/TTFRange.HC"')
            if unit == 'ToTheFront' and args.original_key_poll:
                commands.append('#include "C:/TTFKeyPoll.HC"')
            if unit == 'ToTheFront' and args.original_task_settings:
                commands.extend((
                    'AdamFile("/Adam/AutoComplete/MakeAC.HC",FALSE);',
                    'AdamFile("/Adam/TaskSettings.HC",FALSE);',
                ))
            paths = fire_units if unit == 'TTFFire' and fire_units else [path]
            commands.extend(f'#include "C:{name}"' for name in paths)
            if unit == 'TTFVis' and args.visibility_fixture:
                commands.append('#include "C:/TTFVisibility.HC"')
                break
    elif args.split_xcaliber:
        units = [f'#include "C:{path}"' for path in xcaliber_units]
        if args.xcaliber_desktop:
            units[-1:-1] = [
                'AdamFile("/Adam/AutoComplete/MakeAC.HC",FALSE);',
                'AdamFile("/Adam/TaskSettings.HC",FALSE);',
                '#include "/Kernel/SerialDev/KeyCharPollCore.HC"',
            ]
        commands.extend((
            'Cd("C:/Apps/X-Caliber");',
            '#include "C:/Apps/X-Caliber/XCCtrls.HC"',
            *units,
        ))
    elif args.vertex_trace:
        commands.append('#include "C:/BallGenTrace.HC"')
    else:
        commands.append(f'#include "C:/Apps/{args.app}/Load.HC"')
    if args.combined_loader:
        commands = ['#include "C:/Apps/ToTheFront/NativeLoadProbe.HC"']
    report['completed_commands'] = []
    for command in commands:
        report['command']=command
        guest.command(command)
        report['completed_commands'].append(command)
    if args.visibility_fixture:
        guest.wait('TTF visibility captured\n')
        report['visibility'] = struct.unpack('<12q', (guest.out/'TTFVisibility.bin').read_bytes())
    if args.xcaliber_play:
        exercise = runpy.run_path('build/xcaliber-reference-v1/workflow.py')['exercise']
        report['play'] = {'fixture_sha256': hashlib.sha256(extras['/XCProbe.HC']).hexdigest()}
        guest.type('#include "C:/XCProbe.HC"')
        guest.press('ret')
        exercise(guest, report['play'], fire=not args.xcaliber_no_fire)
    guest.command('6*7;')
    report['fresh_result']=guest.result_pixels()
    report['result']='pass'
    if args.human_match:
        start = len(guest.collect())
        guest.type('ToTheFront;')
        guest.press('ret')
        guest.wait('COMPILER BREAK ready', start=start)
        time.sleep(12)
        workflow = runpy.run_path('build/tothefront-original-v1/startup.py')
        workflow['play'](guest)
        guest.wait('COMMAND OK\n', timeout=45, start=start)
        report['returned_after_phase'] = True
        guest.command('6*7;')
        report['after_match'] = guest.result_pixels()
    if args.ball_mesh:
        guest.command('#include "C:/BallUI.HC"')
        guest.type('BallUIProbe;')
        guest.press('ret')
        report['ball_mesh'] = runpy.run_path(str(ball_ui/'interactive.py'))['exercise'](guest)
        if args.vertex_trace:
            report['vertex_calls'] = len(trace['read'](out))
        guest.command('6*7;')
        report['after_ball'] = guest.result_pixels()
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
        trace = guest.collect()[start:]
        if 'COMMAND OK\n' not in trace:
            try:
                guest.wait('COMMAND OK\n', timeout=12, start=start)
            except TimeoutError:
                guest.screenshot('ball-after-escape')
        report['ball_form_trace'] = guest.collect()[start:]
        if 'COMMAND OK\n' in report['ball_form_trace']:
            guest.type('PopUpColorLighting;')
            guest.press('ret')
            time.sleep(6)
            guest.screenshot('lighting-chooser')

except Exception as exc:
    report.update(result='fail',error=str(exc))
    if args.xcaliber_refresh_state and guest.p.poll() is None:
        collect = runpy.run_path('build/xcaliber-reference-v1/refresh_state.py')['collect']
        report['refresh_state'] = collect(guest)
    raise
finally:
    if args.xcaliber_input_trace:
        report['input_trace'] = [line for line in guest.collect().splitlines()
                                 if line.startswith('XC ')]
    guest.close()
    (out/'result.json').write_text(json.dumps(report,indent=2)+'\n')
