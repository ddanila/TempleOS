from pathlib import Path

runner = Path('tools/test-i386-budget-mouse.py').resolve()
source = runner.read_text()
for suffix in ['Accts.DD.Z', 'Strs.DD.Z', 'Bgt.DATA.Z']:
    old = f"'/Budget/{suffix}'"
    assert source.count(old)==1
    source = source.replace(old, f"'/Home/Budget/{suffix}'")
needle = "if changed-allowed:raise ValueError('Unrelated file changed: '+repr(changed-allowed))"
assert source.count(needle)==1
source = source.replace(needle,"if changed!=allowed:raise ValueError('Unexpected Home file changes: '+repr(changed^allowed))")
needle = 'paths=[Path(__file__).resolve(),fixture'
assert source.count(needle)==1
source = source.replace(needle,'paths=[Path(__file__).resolve(),Path(wrapper_file).resolve(),fixture')
exec(compile(source,str(runner),'exec'),{
    '__file__':str(runner),'__name__':'__main__','wrapper_file':__file__,
})
