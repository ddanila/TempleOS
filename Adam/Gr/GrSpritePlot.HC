#help_index "Graphics/Sprite;Sprites"
/*
$LK,"CSprite",A="MN:CSprite"$s are stored as a sequence of var
length operations with a 1-byte $LK,"type",A="MN:SPT_PT"$ leading
each operation.  They are stored, one after another,
in a chunk of memory terminated by a $LK,"zero",A="MN:SPT_END"$.
$LK,"Sprite3",A="MN:Sprite3"$() shows how the $LK,"CSprite",A="MN:CSprite"$ unions are used.

$LK,"SpriteElemSize",A="MN:SpriteElemSize"$() will return the size of a single
element, while $LK,"SpriteSize",A="MN:SpriteSize"$() will return the size
of an entire list.  Look at $LK,"sprite_elem_base_sizes",A="MN:sprite_elem_base_sizes"$.

See $MA-X+PU,"::/Apps/GrModels",LM="Cd(\"::/Apps/GrModels\");Dir;View;\n"$ for an example of
making CSprite by hand.  It uses $LK,"SPT_MESH",A="MN:SPT_MESH"$,
one of the most complicated.
*/

#include "::/Adam/Gr/SpriteRenderCore.HC"

#include "/Adam/Gr/SpriteTransformCore.HC"

public U0 SpriteExtents(U8 *elems,I64 *min_x=NULL,I64 *max_x=NULL,
				   I64 *min_y=NULL,I64 *max_y=NULL)
{//Ignores flood fills.
  CDC *dc=DCNew(I32_MAX,I32_MAX,Fs,TRUE);
  DCExtentsInit(dc);
  Sprite3(dc,I32_MAX/2,I32_MAX/2,I32_MAX/2,elems);
  if (dc->min_x<=dc->max_x) {
    dc->min_x-=I32_MAX/2;
    dc->max_x-=I32_MAX/2;
  }
  if (dc->min_y<=dc->max_y) {
    dc->min_y-=I32_MAX/2;
    dc->max_y-=I32_MAX/2;
  }
  if (min_x) *min_x=dc->min_x;
  if (max_x) *max_x=dc->max_x;
  if (min_y) *min_y=dc->min_y;
  if (max_y) *max_y=dc->max_y;
  DCDel(dc);
}

public CDC *Sprite2DC(U8 *elems)
{//Convert sprite to device context.
  CDC *res;
  I64 min_x,max_x,min_y,max_y;
  SpriteExtents(elems,&min_x,&max_x,&min_y,&max_y);
  res=DCNew(max_x-min_x+1,max_y-min_y+1);
  Sprite3(res,-min_x,-min_y,0,elems);
  return res;
}

#include "/Adam/Gr/SpriteInterpolateCore.HC"

#help_index "Graphics/Sprite;DolDoc/Output;StdOut/DolDoc"
#include "/Adam/Gr/DocSpriteCore.HC"

public CDocEntry *Sprite(U8 *elems,U8 *fmt=NULL)
{//Put sprite to the command-line, $LK,"DocPut",A="MN:DocPut"$.
//If you set fmt, then include dollars ("$$SP ...$$") and leave %d for num.
  CDoc *doc;
  if (doc=DocPut)
    return DocSprite(doc,elems,fmt);
  return NULL;
}
