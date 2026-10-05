#!/usr/bin/env python3
"""Check the kernel's explicit FileRuntime binding contract before building."""
import argparse
from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[1]


def check(kernel, runtime):
    array = re.search(r'U8 kernel_files_bindings\[(\d+)\]=\{([^}]+)\};', kernel)
    body = re.search(r'U0 KernelFileLoad\(\)\s*\{(.*?)\n\}', kernel, re.S)
    names = re.search(r'\*names="([^"]+)"', kernel)
    if not array or not body or not names:
        raise ValueError('Review file binding checker: source structure changed')
    indices = [int(value.strip()) for value in array[2].split(',')]
    count = int(array[1])
    providers = names[1].split(r'\0')[:-1]
    if len(indices) != count or len(set(indices)) != count:
        raise ValueError('File binding array has wrong or duplicate initializer count')
    patterns = [r'CI386ModuleBinding bindings\[(\d+)\]',
                r'KernelBindings\(bindings,kernel_files_bindings,(\d+),',
                r'KernelServiceLoad\([^;]*?bindings,(\d+),']
    for pattern in patterns:
        match = re.search(pattern, body[1], re.S)
        if not match or int(match[1]) != count:
            raise ValueError('File loader stack/call counts disagree with provider array')
    if any(index >= len(providers) for index in indices):
        raise ValueError('File binding index is outside published providers')
    imports = set(re.findall(r'^import\s+[^;]*?\b(\w+)\s*\(', runtime, re.M))
    missing = imports - {providers[index] for index in indices}
    if missing:
        raise ValueError('File imports missing from kernel bindings: '+', '.join(sorted(missing)))
    return count


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--root', type=Path, default=ROOT)
    args = parser.parse_args()
    count = check((args.root/'Kernel/I386/Kernel.HC').read_text(),
                  (args.root/'Kernel/I386/FileRuntime.HC').read_text())
    print(f'PASS: {count} explicit FileRuntime bindings and consistent loader counts')


if __name__ == '__main__':
    main()
