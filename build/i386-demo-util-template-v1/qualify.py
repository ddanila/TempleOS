"""Validate Util1's complete link list against the frozen inventory."""
import hashlib
import json
from pathlib import Path, PurePosixPath

HERE = Path(__file__).resolve().parent
BATCH = HERE / 'comparison'
DEMO = 'Demo/Templates/Util1.HC'
DIRECTORY = PurePosixPath('Demo/DolDoc')


def main():
    inventory = json.loads(Path('docs/i386-compatibility-inventory.json').read_bytes())
    entries = inventory['entries']
    paths = sorted(row['path'] for row in entries
                   if PurePosixPath(row['path']).parent == DIRECTORY and row['path'].endswith('.HC'))
    source_sha = next(row['reference_sha256'] for row in entries if row['path'] == DEMO)
    batch = json.loads((BATCH / 'result.json').read_bytes())
    entry = batch['entries'][DEMO]
    if not batch['inputs_unchanged'] or 'error' in batch or entry['source_sha256'] != source_sha:
        raise ValueError('The pinned template did not complete on both guests')
    documents = {}
    for side, drive in (('original', 'T'), ('native', 'C')):
        expected = ''.join(f'$LK,"{drive}:/{path}",A="FI:{drive}:/{path}"$\n' for path in paths)
        data = (BATCH / side / entry['output_file']).read_bytes()
        digest = hashlib.sha256(data).hexdigest()
        if data != expected.encode('ascii') + b'\x05' or digest != entry[side + '_sha256']:
            raise ValueError(f'The {side} file-link document differs from the pinned path list')
        documents[side] = digest
    print(json.dumps(dict(result='pass', image_sha256=batch['input_sha256'], source_sha256=source_sha,
                          document_sha256=documents, file_links=len(paths), paths=paths), indent=2))


if __name__ == '__main__':
    main()
