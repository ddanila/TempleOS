from pathlib import Path

runner = Path('tools/test-i386-psalmody-keyboard.py').resolve()
candidate = Path(__file__).with_name('PsalmodyMain.HC').resolve()
source = runner.read_text()
anchor = "            (overlay/'Once.HC').write_bytes("
assert source.count(anchor)==1
source = source.replace(anchor, """            (overlay/'Apps/Psalmody/PsalmodyMain.HC').write_bytes(candidate.read_bytes())
""" + anchor)
source = source.replace('paths=[Path(__file__).resolve(),fixture,',
                        'paths=[Path(__file__).resolve(),fixture,candidate,wrapper,')
exec(compile(source,str(runner),'exec'), {
    '__file__':str(runner), '__name__':'__main__',
    'candidate':candidate, 'wrapper':Path(__file__).resolve(),
})
