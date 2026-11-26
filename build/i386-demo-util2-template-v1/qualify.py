"""Check Util2's complete recursive report and the fixture's readback gate."""
import hashlib
import json
from pathlib import Path

HERE = Path(__file__).resolve().parent
BATCH = HERE / 'fixed'
ORIGINAL_WARNING = (
    b'PrsFun PrsGlblVarLst PrsStmt &LexStmt2Bin $FG,4$$BK,1$WARNING:$FG$$BK,0$ Unused var\n'
    b' $LK,"FL:T:/Demo/Templates/Util2.HC,18"$ \'fuf_flags\' in \'MyUtilDoc\'\n'
)


def expected_report(drive):
    root = f'{drive}:/Util2Check'
    setup = (f'Make Directory:{root}\nMake Directory:{root}/Sub\n').encode('ascii')
    body = (f'Processing Directory: {root}/Sub\n'
            f'       4:{root}/Sub/Beta.DD\n'
            f'       2:{root}/Alpha.DD\n'
            'Total:6\n').encode('ascii') + b'\x05'
    return setup, body


def verify(data, drive):
    setup, body = expected_report(drive)
    if drive == 'B':
        return data == setup + ORIGINAL_WARNING + body
    return data == setup + b'Warning: Unused var\n' + body


def main():
    batch_bytes = (BATCH / 'result.json').read_bytes()
    batch = json.loads(batch_bytes)
    if not batch['inputs_unchanged'] or 'error' in batch:
        raise ValueError('A guest did not finish the document readback checks')
    entry = batch['entries']['Demo/Templates/Util2.HC']
    documents = {}
    for side, drive in (('original', 'B'), ('native', 'C')):
        data = (BATCH / side / entry['output_file']).read_bytes()
        digest = hashlib.sha256(data).hexdigest()
        if digest != entry[side + '_sha256'] or not verify(data, drive):
            raise ValueError(f'Unexpected recursive report on the {side} guest: {data!r}')
        documents[side] = digest
    print(json.dumps(dict(result='pass', image_sha256=batch['input_sha256'],
                          source_sha256=entry['source_sha256'],
                          batch_receipt_sha256=hashlib.sha256(batch_bytes).hexdigest(),
                          report_sha256=documents, root_entries=2, nested_entries=4,
                          total_entries=6, documents_verified_after_write=2), indent=2))


if __name__ == '__main__':
    main()
