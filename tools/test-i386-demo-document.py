#!/usr/bin/env python3
"""Compare the checked-in DolDoc demo's records, anchor and binary round trip."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy
import struct
import subprocess

ROOT = Path(__file__).resolve().parents[1]
DOCUMENT = 'Demo/DolDoc/DemoDoc.DD'
EXPECTED = 'DEMO DOC records 2 5 2 1 1 1 1 1 1'
FIXTURE = r'''
U0 DemoDocLog(U8 *s)
{
  while (*s) OutU8(0xE9,*s++);
}
U0 DemoDocContract()
{
  CDoc *doc=DocRead("::/Demo/DolDoc/DemoDoc.DD"),*copy=DocNew;
  CDocEntry *e;
  CDocBin *bin;
  I64 counts[DOCT_TYPES_NUM],size,size2;
  U8 *first,*second,*line;
  MemSet(counts,0,sizeof(counts));
  for (e=doc->head.next;e!=doc;e=e->next)
    counts[e->type_u8]++;
  line=MStrPrint("DEMO DOC records %d %d %d %d %d %d %d %d %d\n",
    counts[DOCT_PAGE_BREAK],counts[DOCT_LEFT_MARGIN],counts[DOCT_RIGHT_MARGIN],
    counts[DOCT_HEADER],counts[DOCT_FOOTER],counts[DOCT_WORD_WRAP],
    counts[DOCT_CURSOR_MOVEMENT],counts[DOCT_ANCHOR],counts[DOCT_SPRITE]);
  DemoDocLog(line);Free(line);
  if (!DocAnchorFind(doc,"MyLittleAnchor") || doc->cur_entry->type_u8!=DOCT_ANCHOR ||
      StrCmp(doc->cur_entry->aux_str,"MyLittleAnchor") || doc->cur_col!=doc->cur_entry->min_col)
    DemoDocLog("FAIL DemoDoc anchor\n");
  if (DocAnchorFind(doc,"NoSuchDemoAnchor"))
    DemoDocLog("FAIL DemoDoc missing anchor\n");
  bin=DocBinFindNum(doc,1);
  if (!bin || !bin->size || !bin->data)
    DemoDocLog("FAIL DemoDoc sprite\n");
  doc->flags|=DOCF_NO_CURSOR;
  copy->flags|=DOCF_NO_CURSOR;
  first=DocSave(doc,&size);
#ifdef I386_PUBLIC_USER_INCLUDED
  DocLoad(copy,first,size);
  second=DocSave(copy,&size2);
  if (size!=size2 || MemCmp(first,second,size))
    DemoDocLog("FAIL DemoDoc round trip\n");
#else
  // The pinned serializer reports a truncated length for page breaks.
  second=first;
  size2=size;
#endif
  line=MStrPrint("EXPORT roundtrip.DD %X %X\n",second,size2);
  DemoDocLog(line);DemoDocLog("DEMO DOC DONE\n");
  Sleep(1000);
  Free(line);if (second!=first) Free(second);Free(first);DocDel(copy);DocDel(doc);
}
DemoDocContract;
'''


def run(image, out, native):
    Guest = runpy.run_path(str(ROOT/'tools/test-i386-autocomplete-interaction.py'))['Guest']
    guest = Guest(image, out, native, reference_cpus=1)
    try:
        if native:
            guest.wait('DONE native kernel startup\n')
            guest.type('#include "C:/Probe/DemoDoc.HC"')
            guest.press('ret')
        log = guest.wait('DEMO DOC DONE\n')
        if EXPECTED not in log.splitlines() or 'FAIL DemoDoc' in log:
            raise ValueError(log[-1600:])
        if native:
            guest.wait('COMMAND OK\n')
            guest.command('6*7;')
            guest.result_pixels()
        return (out/'roundtrip.DD').read_bytes()
    finally:
        guest.close()


def verify_sprite_roundtrip(source, original, native):
    start = source.index(0) + 1
    header = struct.Struct('<IIII')
    number, flags, size, use_count = header.unpack_from(source, start)
    end = start + header.size + size
    if (number, flags, size, use_count) != (1, 0, 237, 1) or len(source) != end:
        raise ValueError('Unexpected pinned DemoDoc sprite record')
    if original != source[:-6] or native != source:
        raise ValueError('Unexpected reference truncation or native round-trip data loss')
    return {'sprite_payload_bytes': size, 'reference_truncated_bytes': 6}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('disk', type=Path)
    parser.add_argument('--out', required=True, type=Path)
    args = parser.parse_args()
    disk, out = args.disk.resolve(), args.out.resolve()
    out.mkdir()
    sha = lambda data: hashlib.sha256(data).hexdigest()
    disk_hash = sha(disk.read_bytes())
    report = dict(result='running', disk_sha256=disk_hash)
    try:
        original = out/'original-source'
        runpy.run_path(str(ROOT/'tools/test-i386-timeclock-reference.py'))['restore_reference'](original)
        source = (original/DOCUMENT).read_bytes()
        pack = runpy.run_path(str(ROOT/'tools/package-i386-native-image.py'))
        if pack['snapshot'](disk.read_bytes())[1]['/'+DOCUMENT][2] != source:
            raise ValueError('Delivered DemoDoc differs from the pinned original')
        report['source_sha256'] = sha(source)
        (original/'Once.HC').write_text(FIXTURE)
        iso = out/'original.iso'
        subprocess.run(['python3', str(ROOT/'tools/build-iso.py'), '--overlay', str(original),
                        '--output', str(iso)], cwd=ROOT, check=True)
        image = out/'native.img'
        pack['package'](disk, image, additions={'/Probe/DemoDoc.HC': FIXTURE.encode()})
        a = run(iso, out/'original', False)
        report['original_sha256'] = sha(a)
        b = run(image, out/'native', True)
        report['native_sha256'] = sha(b)
        report.update(verify_sprite_roundtrip(source, a, b), result='pass',
                      serialized_bytes=len(b), records=EXPECTED)
    except Exception as exc:
        report.update(result='fail', error=str(exc))
        raise
    finally:
        report['inputs_unchanged'] = sha(disk.read_bytes()) == disk_hash
        (out/'result.json').write_text(json.dumps(report, indent=2)+'\n')
    if not report['inputs_unchanged']:
        raise ValueError('Input disk changed')


if __name__ == '__main__':
    main()
