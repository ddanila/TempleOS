from pathlib import Path

runner = Path('tools/test-i386-application-native-load.py').resolve()
source = runner.read_text()
call = """['#include "C:/Apps/'+args.app+'/Load.HC"','6*7;'],64,True)"""
assert source.count(call) == 1
source = source.replace(call, """['AdamFile("C:/Adam/AutoComplete/MakeAC.HC",FALSE);',
        '#include "C:/Apps/'+args.app+'/Load.HC"','6*7;'],64,True,accel='kvm')""")
pins = 'paths=[source,Path(__file__).resolve(),'
assert source.count(pins) == 1
source = source.replace(pins, 'paths=[source,Path(wrapper).resolve(),Path(__file__).resolve(),')
exec(compile(source, str(runner), 'exec'), {
    '__file__': str(runner), '__name__': '__main__', 'wrapper': __file__,
})
