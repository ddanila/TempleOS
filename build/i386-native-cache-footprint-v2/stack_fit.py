"""Calculate the best full-stack placement in a captured physical heap."""
import argparse
import json
from pathlib import Path


def stack_fit(snapshot, request, stack_bytes, alignment, projected_reclaim):
    free = [block.copy() for block in snapshot['blocks'] if not block['live']]
    largest = max(free, key=lambda block: block['span'])
    if largest['span'] - 16 != snapshot['largest_free']:
        raise ValueError('Physical free chain disagrees with heap summary')
    # Spawn's observed request includes the worst-case alignment allowance.
    header_bytes = request - (alignment - 1) - stack_bytes
    if header_bytes <= 0:
        raise ValueError('Request cannot contain the stack and alignment allowance')
    largest['address'] -= projected_reclaim
    largest['span'] += projected_reclaim

    def placement(block):
        start = block['address']
        end = start + block['span']
        stack_start = (start + 16 + header_bytes + alignment - 1) & -alignment
        return {
            'block_start': start,
            'block_end': end,
            'stack_start': stack_start,
            'stack_end': stack_start + stack_bytes,
            'headroom_bytes': end - stack_start - stack_bytes,
        }

    return max(map(placement, free), key=lambda fit: fit['headroom_bytes'])


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('snapshot', type=Path)
    parser.add_argument('--task-request', type=int, required=True)
    parser.add_argument('--stack-bytes', type=int, default=256 * 1024)
    parser.add_argument('--projected-reclaim', type=int, default=0,
                        help='Model a contiguous extension at the start of the largest block')
    args = parser.parse_args()
    if args.projected_reclaim < 0 or args.stack_bytes <= 0 or args.stack_bytes % 4096:
        parser.error('Use nonnegative reclaim and a positive page-rounded stack size')
    fit = stack_fit(json.loads(args.snapshot.read_text()), args.task_request,
                    args.stack_bytes, 4096, args.projected_reclaim)
    print(json.dumps({
        'snapshot': str(args.snapshot),
        'task_request': args.task_request,
        'stack_bytes': args.stack_bytes,
        'projected_reclaim_bytes': args.projected_reclaim,
        **fit,
    }, indent=2))


if __name__ == '__main__':
    main()
