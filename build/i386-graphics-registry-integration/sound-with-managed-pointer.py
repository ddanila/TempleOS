from pathlib import Path

runner = Path('tools/test-i386-sound-effects.py').resolve()
source = runner.read_text()
options = "accel='tcg', qmp_stdio=True, welcome=True,"
assert source.count(options) == 1
source = source.replace(options, "accel='kvm', qmp_stdio=True, welcome=True,"
                        " managed_pointer=True, keep_window_manager=True,")
pin = 'package-i386-native-image.py\', ROOT/\'tools/build-i386-kernel.py\', Path(__file__).resolve()'
assert source.count(pin) == 1
source = source.replace(pin, pin + ', Path(wrapper_file).resolve()')
exec(compile(source, str(runner), 'exec'), {
    '__file__': str(runner), '__name__': '__main__', 'wrapper_file': __file__,
})
