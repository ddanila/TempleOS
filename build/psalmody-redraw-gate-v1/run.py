"""Repeat the exact physical keyboard oracle once the record redraw settles."""
from pathlib import Path
runner = Path('tools/test-i386-psalmody-keyboard.py').resolve()
fixture_override = Path(__file__).with_name('Contract.HC').resolve()
text = runner.read_text().replace(
    "fixture=ROOT/'tests/guest/i386-psalmody-keyboard/Contract.HC'",
    "fixture=fixture_override",
)
exec(compile(text, str(runner), 'exec'), {
    '__file__': str(runner), '__name__': '__main__',
    'fixture_override': fixture_override,
})
