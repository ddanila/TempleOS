#!/usr/bin/env python3
"""Check the kernel's explicit file and compiler runtime binding contracts."""
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
    named = [(int(index), name) for index, name in re.findall(
        r'KernelBinding\(&bindings\[(\d+)\],"([^" ]+)"\);', body[1])]
    total = count + len(named)
    if [index for index, _ in named] != list(range(count, total)):
        raise ValueError('Named File bindings must fill consecutive trailing slots')
    patterns = [(r'CI386ModuleBinding bindings\[(\d+)\]', total),
                (r'KernelBindings\(bindings,kernel_files_bindings,(\d+),', count),
                (r'KernelServiceLoad\([^;]*?bindings,(\d+),', total)]
    for pattern, expected in patterns:
        match = re.search(pattern, body[1], re.S)
        if not match or int(match[1]) != expected:
            raise ValueError('File loader stack/call counts disagree with provider array')
    capacity = re.search(r'KernelBindings\(bindings,kernel_files_bindings,\d+,([^;]+)\);', body[1])
    if not capacity or capacity[1] not in (str(count),
            'sizeof(bindings)/sizeof(CI386ModuleBinding)' if total == count else ''):
        raise ValueError('Indexed File binding capacity must match indexed count')
    if any(index >= len(providers) for index in indices):
        raise ValueError('File binding index is outside published providers')
    imports = set(re.findall(r'^import\s+[^;]*?\b(\w+)\s*\((?!\*)', runtime, re.M))
    imports.update(re.findall(r'^import\s+[^;(]*?\(\*(\w+)\)\s*\(', runtime, re.M))
    supplied = [providers[index] for index in indices] + [name for _, name in named]
    if len(set(supplied)) != total:
        raise ValueError('Duplicate File binding names')
    missing = imports - set(supplied)
    if missing:
        raise ValueError('File imports missing from kernel bindings: '+', '.join(sorted(missing)))
    return total


def check_compiler(kernel, runtime):
    array = re.search(r'U8 kernel_compiler_bindings\[(\d+)\]=\{([^}]+)\};', kernel)
    names = re.search(r'\*names="([^"]+)"', kernel)
    if not array or not names:
        raise ValueError('Review compiler binding checker: source structure changed')
    indices = [int(value.strip()) for value in array[2].split(',')]
    providers = names[1].split(r'\0')[:-1]
    if len(indices) != int(array[1]) or len(set(indices)) != len(indices):
        raise ValueError('Compiler binding array has wrong or duplicate initializer count')
    if any(index >= len(providers) for index in indices):
        raise ValueError('Compiler binding index is outside published providers')
    imports = set(re.findall(r'^import\s+[^;]*?\b(\w+)\s*\((?!\*)', runtime, re.M))
    imports.update(re.findall(r'^import\s+[^;]*?\b(\w+)\s*\[[^]]*\]\s*;', runtime, re.M))
    missing = imports - {providers[index] for index in indices}
    if missing:
        raise ValueError('Compiler imports missing from kernel bindings: '+', '.join(sorted(missing)))
    return len(indices)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--root', type=Path, default=ROOT)
    args = parser.parse_args()
    count = check((args.root/'Kernel/I386/Kernel.HC').read_text(),
                  (args.root/'Kernel/I386/FileRuntime.HC').read_text())
    print(f'PASS: {count} explicit FileRuntime bindings and consistent loader counts')
    count = check_compiler((args.root/'Kernel/I386/Kernel.HC').read_text(),
                           (args.root/'Kernel/I386/CompilerRuntime.HC').read_text())
    print(f'PASS: {count} explicit CompilerRuntime bindings cover declared imports')


if __name__ == '__main__':
    main()
