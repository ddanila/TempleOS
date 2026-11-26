import sys
from pathlib import Path

tool = Path('tools/profile-i386-bible-link.py').resolve()
source = tool.read_text().replace("'-accel','tcg'", "'-accel','kvm'")
before = "            wait('BL first begin\\n',start=begin)"
after = """            wait('BL missing end\\n',start=begin)
            wait('COMMAND OK\\n',start=begin)
            begin=len(log.read_text())
            submit('6*7;')
            wait('INPUT LINE 6*7;\\n',start=begin)"""
assert source.count(before) == 1
source = source.replace(before, after).replace("'BL first end\\n'", "'COMMAND OK\\n'")
source = source.replace("if not samples: raise ValueError('No Bible link samples')",
                        "if not samples and not completed: raise ValueError('No Bible link samples')")
source = source.replace('link_completed=completed', 'followup_completed=completed')
source = source.replace('first full Bible link', 'first command after full Bible link')
sys.argv[0] = str(tool)
exec(compile(source, str(tool), 'exec'), {'__file__': str(tool), '__name__': '__main__'})
