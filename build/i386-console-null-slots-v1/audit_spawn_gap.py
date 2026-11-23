"""Identify the live backing regions immediately above the largest free block."""
import hashlib
import json
from pathlib import Path
import re
import runpy
import struct

root=Path(__file__).resolve().parent
read=runpy.run_path('tools/build-i386-kernel.py')['mutated_file_contents']
path='/Modules/I386/MemoryRuntime.t32m'
report={}
for profile in ('cross','installed'):
    capture=root/f'user8-profile-{profile}'
    memory=(capture/'before-user.bin').read_bytes()
    snapshot=json.loads((capture/'before-user.json').read_text())
    receipt=json.loads((capture/'result.json').read_text())
    digest=hashlib.sha256(memory).hexdigest()
    assert digest==receipt['snapshots']['before-user']['memory_sha256']
    module=read(capture/'working.img',{path})[path]
    assert hashlib.sha256(module).hexdigest()==snapshot['module_sha256'][path]
    count,records=struct.unpack_from('<2I',module,20)
    offset,=[offset for i in range(count)
             for kind,offset,name,length in [struct.unpack_from('<4I',module,records+i*16)]
             if kind==3 and module[name:name+length]==b'memory_pool']
    match=re.search(r'^MEMORY ([0-9A-F]+) ',(capture/'guest/debug.log').read_text(),re.M)
    pool=int(match[1],16)+8+offset
    owned,signature,quantum,count=struct.unpack_from('<4I',memory,pool+0x544)
    assert signature==0x53323342
    regions={}
    while owned:
        assert owned not in regions and len(regions)<count
        _,_,kind,flags,base,size,owner,used,next_owned,request,span,hold=struct.unpack_from('<5IQ6I',memory,owned)
        assert kind==1 and not flags and owner==pool and 0<=used<=size and hold<=1
        regions[owned]=dict(base=base,capacity=size,used=used,request=request,span=span,held=bool(hold))
        owned=next_owned
    assert len(regions)==count
    blocks=snapshot['blocks']
    index=max((i for i,b in enumerate(blocks) if not b['live']),key=lambda i:blocks[i]['span'])
    gap=blocks[index]
    neighboring=[]
    for block in blocks[index+1:index+3]:
        if not block['live']:
            break
        region=regions.get(block['address']+16)
        if not region:
            break
        assert block['requested']==region['request'] and block['span']==region['span']
        neighboring.append(dict(address=block['address'],**region))
    report[profile]=dict(snapshot_sha256=digest,largest_free=gap['span']-16,
                         first_address=gap['address'],upper_backing_regions=neighboring,
                         pool_quantum=quantum,
                         empty_unheld_regions=sum(not r['used'] and not r['held'] for r in regions.values()))
(root/'spawn-gap-neighbors.json').write_text(json.dumps(report,indent=2)+'\n')
