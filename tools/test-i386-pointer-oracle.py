#!/usr/bin/env python3
"""Reject broken pointer/display oracles using the documented native public ABI."""
from pathlib import Path
import runpy
import struct

api=runpy.run_path(str(Path(__file__).with_name('i386-pointer-oracle.py')))
check=api['pointer_oracle'];Error=api['PointerOracleError']
task=0x110000;table=0x120000;body=0x130000;entry=0x140000;name=0x160000
base=0x170000;type_name=0x180000;storage=0x190000;literal=0x1A0000
memory=bytearray(8*1024*1024)
def word(offset,value):struct.pack_into('<I',memory,offset,value)
def quad(offset,value):struct.pack_into('<Q',memory,offset,value)
word(task,task);word(task+4,int.from_bytes(b'TskS','little'));word(task+824,table)
quad(table+4,1);word(table+20,body);word(body,entry)
word(entry+4,name);word(entry+8,8);memory[name:name+5]=b'lost\0'
quad(entry+36,4);word(entry+52,base+80);word(entry+80,storage)
word(base+4,type_name);memory[type_name:type_name+3]=b'U8\0';memory[base+57]=5
quad(base+80+36,4);memory[base+80+56:base+80+58]=bytes((1,10))
word(storage,literal);memory[literal:literal+4]=b'bad\0';quad(task+772,literal);memory[task+766]=10
assert check(memory,task,'lost',b'bad')['answer']=='0x1A0000'
cases=[('missing global',entry+8,b'\0'*4),('wrong literal',literal,b'X'),
 ('wrong result',task+772,struct.pack('<Q',literal+1)),('wrong category',task+766,b'\x09'),
 ('unconsumed answer',task+765,b'\x01'),('wrong pointer type',base+80+56,b'\0'),
 ('wrong base type',base+57,b'\x04'),('wrong global size',entry+36,struct.pack('<Q',8)),
 ('invalid storage',entry+80,struct.pack('<I',len(memory))),('wrong task',task,b'\0'*4)]
for label,offset,value in cases:
 candidate=memory.copy();candidate[offset:offset+len(value)]=value
 try:check(candidate,task,'lost',b'bad')
 except Error:pass
 else:raise AssertionError(label+' was accepted')
cycle=memory.copy();struct.pack_into('<I',cycle,entry,entry);struct.pack_into('<I',cycle,entry+8,0)
try:check(cycle,task,'lost',b'bad')
except Error:pass
else:raise AssertionError('Hash cycle was accepted')
print('PASS: native pointer oracle plus 11 corruption/missing-state guards')
