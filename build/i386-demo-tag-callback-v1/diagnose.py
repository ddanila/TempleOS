"""Compare the task field and accessor before clearing the callback border."""
import argparse
from pathlib import Path
import runpy
import shutil


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('image', type=Path)
    parser.add_argument('out', type=Path)
    args = parser.parse_args()
    args.out.mkdir()
    image = args.out / 'working.img'
    shutil.copyfile(args.image, image)
    guest_type = runpy.run_path('tools/test-i386-autocomplete-interaction.py')['Guest']
    guest = guest_type(image, args.out / 'native', True)
    try:
        guest.wait('DONE native kernel startup\n')
        commands = {
            'launch': 'ExeFile("C:/Demo/DolDoc/CallBack.HC");',
            'pointers': '"%X %X %X\u005c\u005cn",Fs->border_doc,DocBorder,DocPut;',
            'sizes-before': '"%d %d\u005c\u005cn",DocSize(DocBorder),DocSize(DocPut);',
            'accessor-clear': 'DocClear(DocBorder);',
            'sizes-after': '"%d %d\u005c\u005cn",DocSize(DocBorder),DocSize(DocPut);',
            'reinstall': 'DoIt;',
            'field-clear': 'UndoIt;',
        }
        for name, command in commands.items():
            start = len(guest.collect())
            guest.command(command)
            if 'INPUT REJECT ' in guest.collect()[start:]:
                raise ValueError(guest.collect()[start:][-2000:])
            guest.screenshot(name)
    finally:
        guest.close()


if __name__ == '__main__':
    main()
