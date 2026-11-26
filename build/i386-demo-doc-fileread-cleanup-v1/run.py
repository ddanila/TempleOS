"""Compare the shipped FileRead cleanup fix to the unchanged original output."""
from pathlib import Path
import sys

tool = Path('tools/test-i386-demo-batch.py').resolve()
source = tool.read_text().replace('import runpy\n', 'import runpy\nimport re\n')
source = source.replace('if original != native:',
    'if native != original.replace(b"  Free(flags_stats);\\n", '
    'b"  Free(flags_stats);\\n  Free(type_flags_stats);\\n"):')
function = r'''
U0 DemoFileReadCleanup()
{
  CHashFun *fun=HashFind("DocProfile",Fs->hash_table,HTT_FUN);
  U0 (*profile)(U8 *,I64);
  CDoc *put=DocPut,*doc;
  I64 before=Fs->data_heap->used_u8s;
  U8 line[96];
  if(!fun) throw('Batch',TRUE);
  profile=fun->exe_addr;
  doc=DocNew;
  Fs->put_doc=doc;
  Msg(MSG_KEY_DOWN,'c',0x2E);
  (*profile)("::/Doc/Welcome.DD",0);
  Fs->put_doc=put;
  DocDel(doc);
  StrPrint(line,"FILE READ HEAP DELTA %d\n",Fs->data_heap->used_u8s-before);
  DemoBatchLog(line);
}
'''
source = source.replace('U0 DemoBatchRun(', function+'U0 DemoBatchRun(')
source = source.replace('  ExeFile(path);', '''  WinHorz(0,78);
  DefineLoad("DD_TEMPLEOS_LOC","80,849");
  Msg(MSG_KEY_DOWN,'a',0x1E);Msg(MSG_KEY_DOWN,'b',0x30);
  ExeFile(path);''')
source = source.replace('Free(line);Free(data);DocDel(doc);Raw(raw);',
    'Free(line);Free(data);DocDel(doc);DemoFileReadCleanup;Raw(raw);')
anchor = "        report['result'] = 'pass' if all(e['result'] == 'pass' for e in report['entries'].values()) else 'fail'"
assert source.count(anchor) == 1
source = source.replace(anchor, anchor+'''
        deltas = {}
        for name in ('original','native'):
            log = (out/name/'debug.log').read_text()
            rows = re.findall(r'^FILE READ HEAP DELTA (-?\\d+)$',log,re.M)
            if len(rows)!=1:
                raise ValueError(f'Missing allocator delta for {name}')
            deltas[name] = int(rows[0])
        report['profile_heap_delta'] = deltas
        if deltas['original'] < 512 or deltas['native'] != 0:
            raise ValueError(f'Unexpected FileRead cleanup: {deltas}')
''')
sys.argv[0] = str(tool)
exec(compile(source, str(tool), 'exec'), {'__file__': str(tool), '__name__': '__main__'})
