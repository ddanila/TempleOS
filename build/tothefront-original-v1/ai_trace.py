"""Observe the selected target and the two random calls in a failed SimpleAI move."""

AI_PATH = '/Apps/ToTheFront/AIs/SimpleAI.HC'


def instrument(source):
    anchor = b'UnitMove(tmpu,x+RandI16,y+RandI16);'
    if source.count(anchor) != 1:
        raise ValueError('Expected one SimpleAI fallback expression')
    move = b'if (!UnitMove(tmpu,x,y)) {'
    if source.count(move) != 1:
        raise ValueError('Expected one SimpleAI targeted move')
    helper = b'''U0 TTFAITarget(Unit *unit,Unit *target)
{
  U8 line[160],*p;
  StrPrint(line,"TTF AI target %d %d %d %d %d %d %d %d\\n",turn,unit->num,
      unit->row,unit->col,unit->facing,target->num,target->row,target->col);
  p=line;
  while (*p) OutU8(0xE9,*p++);
}

I16 TTFRandArg(I64 unit,I64 axis)
{
  I16 value=RandI16;
  U8 line[128],*p;
  StrPrint(line,"TTF AI random %d %d %d %d %X\\n",turn,unit,axis,value,Fs->rand_seed);
  p=line;
  while (*p) OutU8(0xE9,*p++);
  return value;
}
'''
    source = source.replace(move, b'TTFAITarget(tmpu,target);\n\t' + move)
    return helper + source.replace(
        anchor, b'UnitMove(tmpu,x+TTFRandArg(i,0),y+TTFRandArg(i,1));')
