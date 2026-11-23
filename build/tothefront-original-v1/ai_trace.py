"""Observe the selected target and the two random calls in a failed SimpleAI move."""

AI_PATH = '/Apps/ToTheFront/AIs/SimpleAI.HC'


def instrument(source):
    anchor = b'UnitMove(tmpu,x+RandI16,y+RandI16);'
    if source.count(anchor) != 1:
        raise ValueError('Expected one SimpleAI fallback expression')
    move = b'if (!UnitMove(tmpu,x,y)) {'
    if source.count(move) != 1:
        raise ValueError('Expected one SimpleAI targeted move')
    compare = b'if (dd<=range && dd<best_dd) {'
    if source.count(compare) != 1:
        raise ValueError('Expected one SimpleAI distance comparison')
    helper = b'''U0 TTFAIDistance(I64 row,I64 col,I64 candidate,F64 x1,F64 y1,F64 x2,F64 y2)
{
  F64 dx=x2-x1,dy=y2-y1,distance=Sqr(x2-x1)+Sqr(y2-y1);
  U8 line[256],*p;
  StrPrint(line,"TTF AI distance %d %d %d %016X %016X %016X %016X %016X %016X %016X\\n",
      row,col,candidate,*(&x1)(U64 *),*(&y1)(U64 *),*(&x2)(U64 *),*(&y2)(U64 *),
      *(&dx)(U64 *),*(&dy)(U64 *),*(&distance)(U64 *));
  p=line;
  while (*p) OutU8(0xE9,*p++);
}

U0 TTFAITarget(Unit *unit,Unit *target)
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
    source = source.replace(compare, b'if (row==28 && (col==1 || col==5) && (i==10 || i==11))\n'
                                     b'          TTFAIDistance(row,col,i,x1,y1,x2,y2);\n        ' + compare)
    source = source.replace(move, b'TTFAITarget(tmpu,target);\n\t' + move)
    return helper + source.replace(
        anchor, b'UnitMove(tmpu,x+TTFRandArg(i,0),y+TTFRandArg(i,1));')
