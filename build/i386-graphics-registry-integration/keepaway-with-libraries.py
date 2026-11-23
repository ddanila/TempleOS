from pathlib import Path

runner = Path('tools/test-i386-application-native-load.py').resolve()
source = runner.read_text()
commands = "['#include \"C:/Apps/'+args.app+'/Load.HC\"','6*7;']"
assert source.count(commands) == 1
source = source.replace(commands, """
['AdamFile("C:/Adam/AutoComplete/MakeAC.HC",FALSE);',
 'AdamFile("C:/Adam/TaskSettings.HC",FALSE);',
 '#include "C:/Apps/'+args.app+'/Load.HC"', '6*7;']""".strip())
source = source.replace("],64,True)", "],64,True,accel='kvm')")
pins = 'paths=[source,Path(__file__).resolve(),'
assert source.count(pins) == 1
source = source.replace(pins, 'paths=[source,Path(wrapper_file).resolve(),Path(__file__).resolve(),')
exec(compile(source, str(runner), 'exec'), {
    '__file__': str(runner), '__name__': '__main__', 'wrapper_file': __file__,
})
