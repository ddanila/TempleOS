set pagination off
set confirm off
python
import gdb

base = int(gdb.parse_and_eval('$file_base')) + 8 - 32
active = False

def reg(name):
    return int(gdb.parse_and_eval('$' + name)) & 0xffffffff

class Stage(gdb.Breakpoint):
    def __init__(self, name, offset):
        super().__init__(f'*{base + offset:#x}', internal=True)
        self.name = name

    def stop(self):
        global active
        if self.name == 'stored entry':
            ptr = int.from_bytes(bytes(gdb.selected_inferior().read_memory(reg('esp') + 12, 4)), 'little')
            path = bytes(gdb.selected_inferior().read_memory(ptr, 40)).split(b'\0', 1)[0]
            active = b'TimeFile.DATA' in path
            if active:
                print(self.name, path, flush=True)
        elif active:
            print(f'{self.name} eax={reg("eax"):#010x} flags={reg("eflags"):#010x}', flush=True)
            if self.name == 'stored return':
                active = False
        return False

for name, offset in (
    ('stored entry', 0x1aea0),
    ('stored return', 0x1af60),
    ('file load entry', 0xc0f0),
    ('file load returned', 0xed72),
    ('begin returned', 0xc1f4),
    ('direct resolve returned', 0xc29d),
    ('file locate returned', 0xc33f),
    ('raw payload returned', 0xc3f2),
    ('end returned', 0xc614),
):
    Stage(name, offset)
end
continue
