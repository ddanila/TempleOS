"""Require an original-format DolDoc tree from the filename save workflow."""
import argparse
import hashlib
import json
from pathlib import Path


EXPECTED = (
    b'$TR-C,""$\n$ID,2$$TR,""$$MA,"Proof",LM="Cd(\\"Z:/Proof\\");Dir;\\n"$\n'
    b'$ID,2$$LK,"Leaf.TXT",A="FI:Z:/Proof/Leaf.TXT"$\n'
    b'$ID,-2$$LK,"Root.TXT",A="FI:Z:/Root.TXT"$\n$ID,-2$\x05'
)


def sha(data):
    return hashlib.sha256(data).hexdigest()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('run', type=Path)
    args = parser.parse_args()
    receipt = json.loads((args.run / 'result.json').read_bytes())
    if not receipt['inputs_unchanged']:
        raise ValueError('Input changed')
    documents = {}
    for side in ('original', 'native'):
        run = receipt['runs'][side]
        if run['result'] != 'saved':
            raise ValueError(f'{side} did not save through the form')
        output = args.run / side
        if sha((output / 'save-form.png').read_bytes()) != run['screenshot_sha256']:
            raise ValueError(f'{side} save form capture changed')
        document = (output / 'tree.DD').read_bytes()
        if document != EXPECTED or sha(document) != run['document_sha256']:
            raise ValueError(f'{side} directory tree differs')
        documents[side] = run['document_sha256']
    print(json.dumps(dict(result='pass', bytes=len(EXPECTED), document_sha256=documents,
                          fresh_result=receipt['runs']['native']['fresh_result']), indent=2))


if __name__ == '__main__':
    main()
