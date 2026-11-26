#help_index "Graphics/Sprite;Sprites"
#help_file "::/Doc/Sprite"

U8 polypt_map[9]={0,1,2,3,0,4,5,6,7};

#include "/Adam/Gr/SpriteRecordsCore.HC"

U0 SpriteSelAll(U8 *elems,Bool val)
{
  CSprite *tmpg=elems-offset(CSprite.start);
  while (tmpg->type&SPG_TYPE_MASK) {
    BEqu(&tmpg->type,SPf_SEL,val);
    tmpg(U8 *)+=SpriteElemSize(tmpg);
  }
}

#include "/Adam/Gr/DC2SpriteCore.HC"

#include "/Adam/Gr/SpriteSummaryCore.HC"
