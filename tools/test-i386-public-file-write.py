#!/usr/bin/env python3
"""Check original FileWrite cluster return, binary bytes and explicit metadata."""
import argparse
import hashlib
import json
from pathlib import Path
import re
import runpy
import struct

ROOT = Path(__file__).resolve().parents[1]
WANTED = '/Probe/PublicWrite.BIN'
DATE = 0x1122334455667788


def find_record(disk, wanted):
    image = disk.read_bytes()
    root = struct.unpack_from('<q', image, 2048*512+24)[0]
    seen = set()
    def walk(block, path):
        if block in seen:
            raise ValueError('Repeated directory')
        seen.add(block)
        _, _, _, size, _ = struct.unpack_from('<H38sqqQ', image, block*512)
        for offset in range(block*512+128, block*512+size, 64):
            attr, raw, child, length, date = struct.unpack_from('<H38sqqQ', image, offset)
            name = raw.split(b'\0',1)[0].decode('ascii')
            if not name:
                break
            if attr & 0x100:
                continue
            full = path+'/'+name
            if full == wanted:
                return dict(attr=attr, block=child, bytes=length, date=date)
            if attr & 0x10:
                found = walk(child, full)
                if found:
                    return found
        return None
    return walk(root, '')


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('disk', type=Path)
    parser.add_argument('--out', type=Path, required=True)
    args = parser.parse_args()
    out = args.out.resolve()
    out.mkdir(parents=True, exist_ok=True)
    candidate = out/'candidate.img'
    if candidate == args.disk.resolve():
        parser.error('candidate must not overwrite source')
    original = args.disk.read_bytes()
    candidate.write_bytes(original)
    (out/'result.json').unlink(missing_ok=True)
    report = dict(result='fail', source_disk_sha256=hashlib.sha256(original).hexdigest(),
                  scope='Original five-argument FileWrite: positive cluster matches persisted binary file and explicit timestamp/contiguous attribute; not full file API parity')
    commands = [
        ('U8 WriteBytes[4]={65,0,66,255};', []),
        ('U0 WriteReport(I64 v){U8 *s="FILEWRITE BLOCK ",*digits="0123456789ABCDEF";I64 i;while(*s)OutU8(0xE9,*s++);for(i=60;i>=0;i-=4)OutU8(0xE9,digits[(v>>i)&15]);OutU8(0xE9,10);}', []),
        (f'I64 WriteBlock=FileWrite("C:{WANTED}",WriteBytes,4,{DATE},0x800);WriteBlock>0;', ['1']),
        ('WriteReport(WriteBlock);', []), ('6*7;', ['42'])]
    try:
        runner = runpy.run_path(str(ROOT/'tools/i386-kernel-input.py'))['run_input']
        report['behavior'] = runner(candidate,out/'behavior',snapshot=False,
            cpu='486,-fpu',qmp_stdio=True,startup_check={'status':'ok','answers':[],'commands':commands})
        build = runpy.run_path(str(ROOT/'tools/build-i386-kernel.py'))
        report['filesystem'] = build['verify_mutated_volume'](candidate)
        payload = build['mutated_file_contents'](candidate,{WANTED}).get(WANTED)
        entry = find_record(candidate,WANTED)
        blocks = re.findall(r'^FILEWRITE BLOCK ([0-9A-F]{16})$', (out/'behavior/debug.log').read_text(),re.M)
        if len(blocks)!=1 or not entry or int(blocks[0],16)!=entry['block']:
            raise ValueError('FileWrite return differs from persisted cluster')
        if payload!=b'A\0B\xff' or entry['bytes']!=4 or entry['date']!=DATE or entry['attr']!=0x800:
            raise ValueError('FileWrite persisted bytes or metadata differ')
        report.update(result='pass',entry=entry)
    except Exception as error:
        report['error']=str(error)
        raise
    finally:
        report['source_disk_unchanged']=args.disk.read_bytes()==original
        if not report['source_disk_unchanged']:
            report.update(result='fail',error='Source disk changed')
        (out/'result.json').write_text(json.dumps(report,indent=2)+'\n')


if __name__=='__main__':
    main()
