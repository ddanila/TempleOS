"""Mark the first draw pass that sees a queued X-Caliber shot."""


def instrument(source):
    helper = b'''Bool xc_shot_draw_seen=FALSE;

U0 XCShotDrawLog(U8 *p)
{
  while (*p) OutU8(0xE9,*p++);
}

'''
    declaration = b'  Bool draw_laser_line=FALSE;'
    if source.count(declaration) != 1:
        raise ValueError('Missing draw locals')
    source = source.replace(declaration, declaration + b'\n  Bool trace_shot=FALSE;')
    start = b'  if (ode!=task->last_ode) return;'
    if source.count(start) != 1:
        raise ValueError('Missing draw ownership guard')
    source = source.replace(start, start + b'''
  if (!xc_shot_draw_seen && shot_head.next!=&shot_head) {
    xc_shot_draw_seen=TRUE;
    trace_shot=TRUE;
    XCShotDrawLog("XC draw shot frame\\n");
  }
''')
    stages = (
        (b'  tmpm=ode->next_mass;', 'before masses'),
        (b'  tmpsps=ode->next_spring;', 'before springs'),
        (b'  tmpsp=ship_head.next;', 'before ships'),
        (b'  tmps=shot_head.next;', 'before shots'),
        (b'  if (human && draw_laser_line) {', 'after shots'),
    )
    for marker, label in stages:
        if source.count(marker) != 1:
            raise ValueError(f'Missing unique draw stage {marker!r}')
        trace = f'  if (trace_shot) XCShotDrawLog("XC draw {label}\\n");\n'.encode()
        source = source.replace(marker, trace + marker)
    end = source.rfind(b'\n}')
    if end < 0:
        raise ValueError('Missing draw function end')
    return helper + source[:end] + b'\n  if (trace_shot) XCShotDrawLog("XC draw returned\\n");' + source[end:]
