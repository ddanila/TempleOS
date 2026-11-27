"""Bound an alternative backing placement in the captured pre-User heap."""
from pathlib import Path
import json

ROOT = Path(__file__).resolve().parents[1]
HEADER_BYTES = 16
TASK_REQUEST = 267527
TERMINAL_CELLS = 43200


def extent(payload):
    return (payload + 7) // 8 * 8 + HEADER_BYTES


def main():
    snapshot = ROOT / 'i386-user8-fragmentation-v1/result.json'
    before = json.loads(snapshot.read_text())['before-user']
    spans = before['largest_free_spans']
    left, right = sorted(spans[:2], key=lambda span: span['address'])
    other = spans[2]
    regions = before['backing_regions_between_two_largest_spans']
    assert left['address'] + left['span'] == regions[0]['block_address']
    assert regions[0]['block_address'] + regions[0]['span'] == regions[1]['block_address']
    assert regions[1]['block_address'] + regions[1]['span'] == right['address']
    # CMemRange plus pool, owner and accounting fields, with worst case page padding.
    alternate = sum(extent(region['page_bytes'] + 52 + 511) for region in regions)
    assert other['span'] >= alternate
    if_only_one_replaced = [max(left['span'] + regions[0]['span'], right['span']),
                            max(left['span'], regions[1]['span'] + right['span'])]
    candidate = right['address'] + right['span'] - left['address']
    assert max(if_only_one_replaced) < extent(TASK_REQUEST)
    assert candidate >= extent(TASK_REQUEST) + extent(TERMINAL_CELLS)
    print(json.dumps({
        'scope': 'Counterfactual fit in the captured heap. Allocation chronology and User startup require runtime verification.',
        'current_largest_payload': before['largest_free_payload_bytes'],
        'largest_payload_if_one_region_was_elsewhere':
            [span - HEADER_BYTES for span in if_only_one_replaced],
        'largest_payload_if_both_regions_were_elsewhere': candidate - HEADER_BYTES,
        'available_alternate_span_bytes': other['span'],
        'alternate_span_needed_with_maximum_padding': alternate,
        'joined_span_remaining_after_task_and_terminal_cells':
            candidate - extent(TASK_REQUEST) - extent(TERMINAL_CELLS),
    }, indent=2))


if __name__ == '__main__':
    main()
