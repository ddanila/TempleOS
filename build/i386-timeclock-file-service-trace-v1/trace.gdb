set pagination off
set confirm off
python
import gdb

class Leave(gdb.FinishBreakpoint):
    def __init__(self, stage):
        super().__init__(gdb.newest_frame(), internal=True)
        self.stage = stage

    def stop(self):
        eax = int(gdb.parse_and_eval('$eax')) & 0xffffffff
        print(f'{self.stage} returns {eax:#010x}', flush=True)
        return False

class Enter(gdb.Breakpoint):
    def __init__(self, stage, addr):
        super().__init__(f'*{addr:#x}', internal=True)
        self.stage = stage

    def stop(self):
        sp = int(gdb.parse_and_eval('$esp')) & 0xffffffff
        inferior = gdb.selected_inferior()
        args = bytes(inferior.read_memory(sp + 4, 24))
        if self.stage == 'stored':
            ptr = int.from_bytes(args[8:12], 'little')
            name = bytes(inferior.read_memory(ptr, 40)).split(b'\0', 1)[0]
            if b'TimeFile.DATA' not in name:
                return False
            print(f'stored reads {name!r}', flush=True)
        else:
            ptr = int.from_bytes(args[8:12], 'little')
            size = int.from_bytes(args[16:24], 'little')
            if size != 50:
                return False
            raw = bytes(inferior.read_memory(ptr, size))
            print(f'expand reads {raw.hex()}', flush=True)
        Leave(self.stage)
        return False

Enter('stored', int(gdb.parse_and_eval('$file_base')) + 8 + 0x1ae80)
Enter('expand', int(gdb.parse_and_eval('$file_base')) + 8 + 0xadc0)
end
continue
