"""Trace the unmodified Human order flow on a disposable source overlay."""
from pathlib import Path


def instrument(source):
    start = source.index(b'U0 PlayerDirect()')
    prefix, direct = source[:start], source[start:]

    def insert(body, anchor, replacement):
        if body.count(anchor) != 1:
            raise ValueError(f'Expected one match: {anchor!r}')
        return body.replace(anchor, replacement)

    direct = insert(direct, b'	      VisRecalc(VR_ONE_FRIENDLY_UNIT,tmpu);',
                    b'	      TTFDriveLog("TTF selected before visibility\\n");\n'
                    b'	      VisRecalc(VR_ONE_FRIENDLY_UNIT,tmpu);\n'
                    b'	      TTFDriveLog("TTF selected after visibility\\n");')
    direct = insert(direct, b'      case MSG_MS_L_UP:\n',
                    b'      case MSG_MS_L_UP:\n'
                    b'        TTFDriveLog("TTF release received\\n");\n')
    direct = insert(direct, b'	      UnitDirectFire(tmpu,target);',
                    b'	      {\n'
                    b'                TTFDriveLog("TTF before shot\\n");\n'
                    b'                UnitDirectFire(tmpu,target);\n'
                    b'                TTFDriveLog("TTF after shot\\n");\n'
                    b'              }')
    helper = b'U0 TTFDriveLog(U8 *p){while(*p)OutU8(0xE9,*p++);}\n'
    return prefix + helper + direct


def instrument_shot(source):
    start = source.index(b'U0 UnitDirectFire(')
    end = source.index(b'Bool HexOccupy(', start)
    body = source[start:end]
    locations = (
        (b'  AttackHeader(tmpu,"DirectFire",target);', 'attack header'),
        (b'  d=100*Rand;', 'roll'),
        (b'    Noise(500*animation_delay,34,41);', 'hit sound'),
        (b'    Sleep(500*animation_delay);', 'hit delay'),
        (b'    Line(NULL,x1,y1,0,x2,y2,0,&BulletPlot);', 'hit line'),
        (b'    Noise(1000*animation_delay,69,74);', 'miss sound'),
        (b'    Line(NULL,x1,y1,0,x2+d*Cos(a),y2+d*Sin(a),0,&BulletPlot);', 'miss line'),
        (b'    DamageDo(target,HitDamage(tmpu,target,facing,range_factor));', 'damage'),
        (b'  target_unit=NULL;', 'cleanup'),
    )
    for instruction, label in locations:
        if body.count(instruction) != 1:
            raise ValueError(f'Expected one shot trace location: {instruction!r}')
        before = f'  TTFShotLog("TTF shot before {label}\\n");'.encode()
        after = f'  TTFShotLog("TTF shot after {label}\\n");'.encode()
        body = body.replace(instruction, b'\n'.join((before, instruction, after)))
    helper = b'U0 TTFShotLog(U8 *p){while(*p)OutU8(0xE9,*p++); }\n'
    return source[:start] + helper + body + source[end:]


def package(disk, working, fixture, snapshot, packer, trace_shot=False):
    name = '/Apps/ToTheFront/AIs/Human.HC'
    original_image = disk.read_bytes()
    original_files = snapshot(original_image)[1]
    replacements = {name: instrument(original_files[name][2])}
    if trace_shot:
        shot = '/Apps/ToTheFront/TTFFire.HC'
        replacements[shot] = instrument_shot(original_files[shot][2])

    return package_replacements(disk, working, fixture, snapshot, packer, replacements)


def package_replacements(disk, working, fixture, snapshot, packer, replacements, additions=None):
    if additions is None:
        additions = {'/TTFPhases.HC': fixture}
    original_image = disk.read_bytes()
    original_files = snapshot(original_image)[1]

    def transformed(raw):
        tree, files, directories = snapshot(raw)
        for name, data in replacements.items():
            node = tree
            for component in name.strip('/').split('/')[:-1]:
                node = node[component][2]
            attributes, date, _ = files[name]
            files[name] = node[Path(name).name] = (attributes, date, data)
        return tree, files, directories

    packer.__globals__['snapshot'] = transformed
    try:
        receipt = packer(disk, working, additions=additions)
    finally:
        packer.__globals__['snapshot'] = snapshot
    final = working.read_bytes()
    delivered = snapshot(final)[1]
    assert final[:2048 * 512] == original_image[:2048 * 512]
    assert delivered.keys() == original_files.keys() | additions.keys()
    assert all(delivered[path] == (attr, date, replacements.get(path, data))
               for path, (attr, date, data) in original_files.items())
    return receipt
