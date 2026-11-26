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

#include "/Adam/Gr/SpriteExtentsCore.HC"

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

#include "/Adam/Gr/SpriteOutputCore.HC"
