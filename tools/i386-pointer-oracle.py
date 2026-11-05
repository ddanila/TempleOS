#!/usr/bin/env python3
"""Resolve a U8 pointer independently from a stopped-command physical RAM dump.

Uses the 32-bit public CTask/CHash* ABI, not rendered text or a predicted allocator
address. The task offsets are asserted by CompilerTaskLayoutProbe.HC. Hash and
symbol layouts follow Kernel/HashTypes.HH, DefineTypes.HH and SymbolTypes.HH.
"""
import struct


class PointerOracleError(AssertionError):
    pass


def pointer_oracle(memory,task,name,literal):
    if len(memory) not in tuple(n*1024*1024 for n in (8,16,64,128)):
        raise PointerOracleError('Unsupported RAM dump size')
    if not isinstance(literal,bytes) or b'\0' in literal:
        raise PointerOracleError('Expected a byte string without a terminator')
    def span(address,size):
        if not 0<address<=len(memory)-size:
            raise PointerOracleError('Pointer outside captured RAM')
        return memory[address:address+size]
    def u32(address):return struct.unpack('<I',span(address,4))[0]
    def u64(address):return struct.unpack('<Q',span(address,8))[0]
    def string(address):
        data=span(address,min(256,len(memory)-address))
        if b'\0' not in data:raise PointerOracleError('Unterminated symbol name')
        return data.split(b'\0',1)[0]
    if u32(task)!=task or u32(task+4)!=int.from_bytes(b'TskS','little'):
        raise PointerOracleError('Console task identity mismatch')
    table=u32(task+824);tables=set();entry=None
    while table:
        if table in tables:raise PointerOracleError('Hash table cycle')
        tables.add(table);mask=u64(table+4);body=u32(table+20)
        if mask>4095 or (mask+1)&mask or u64(table+12):
            raise PointerOracleError('Invalid or locked public hash table')
        span(body,(mask+1)*4);seen=set()
        for index in range(mask+1):
            current=u32(body+index*4)
            while current:
                if current in seen:raise PointerOracleError('Hash entry cycle or repeated entry')
                seen.add(current)
                if len(seen)>65536:raise PointerOracleError('Unbounded hash chain')
                if u32(current+8)&8 and string(u32(current+4))==name.encode():
                    entry=current;break
                current=u32(current)
            if entry is not None:break
        if entry is not None:break
        table=u32(table)
    if entry is None:raise PointerOracleError('Required global is absent')
    if u64(entry+36)!=4 or u64(entry+44)&(2|4|16):
        raise PointerOracleError('Global is not an owned native pointer variable')
    kind=u32(entry+52)
    if u64(kind+36)!=4 or span(kind+56,2)!=bytes((1,10)):
        raise PointerOracleError('Global does not have pointer type metadata')
    base=kind-80
    if span(base+56,2)!=bytes((0,5)) or string(u32(base+4))!=b'U8':
        raise PointerOracleError('Pointer base type is not U8')
    data=u32(entry+80);value=u32(data)
    if span(value,len(literal)+1)!=literal+b'\0':
        raise PointerOracleError('Published pointer does not reference original literal bytes')
    if u64(task+772)!=value or span(task+766,1)!=bytes((10,)) or span(task+765,1)!=b'\0':
        raise PointerOracleError('Consumed task answer differs from the published pointer')
    return dict(task=task,table=table,entry=entry,type=kind,data=data,value=value,
                symbol=name,literal=literal.decode('ascii'),answer='0x'+format(value,'X'))
