"""Compare ShotNew's returned pointer with the shot just appended."""

def instrument(source, *, reference_recoil=False):
    anchor = b'  tmps=ShotNew(MT_ANTIMATTER_BALL,&tmpsp->p[n].x,&v,r,fuse_time,&p1);'
    if source.count(anchor) != 1:
        raise ValueError('Expected one firing call to ShotNew')
    trace = b'''
  if (tmpsp==human) {
    U8 shot_report[192],*shot_report_ptr;
    Shot *queued=shot_head.last;
    F64 recoil_operand=tmps->p.mass,queued_mass=queued->p.mass,queued_vx=queued->p.DxDt;
    StrPrint(shot_report,"XC shot return %X queued %X values %016X %016X %016X\\n",
        tmps,queued,*(&recoil_operand)(U64 *),*(&queued_mass)(U64 *),*(&queued_vx)(U64 *));
    shot_report_ptr=shot_report;
    while (*shot_report_ptr) OutU8(0xE9,*shot_report_ptr++);
  }'''
    if reference_recoil:
        trace = trace.replace(b'recoil_operand=tmps->p.mass', b'recoil_operand=tmps->p.DxDt')
    return source.replace(anchor, anchor + trace)
