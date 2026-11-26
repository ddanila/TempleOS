#help_index "Graphics/Sprite;Sprites"

#include "/Adam/Gr/SpriteToCodeCore.HC"

CSprite *Code2SpriteElem(CCmpCtrl *cc,I64 type)
{
  I64 i,num1,num2,size;
  CSprite *res,g;
  CColorROPU32 color;
  U8 *st,*ptr;
  CQueD3I32 headp,*tmpp,*tmpa1;
  CQueMeshTri headt,*tmpt,*tmpt1;
  CQueVectU8 *tmpv;
  MemSet(&g,0,sizeof(CSprite));
  switch (type) {
    start:
      case SPT_COLOR:
      case SPT_DITHER_COLOR:
	st=LexFirstRem(cc,"}");
	color=Str2ColorU32(st);
	Free(st);
	Lex(cc); //Skip color
	g.c.color=color.c0.color;
	if (color&ROPF_DITHER) {
	  g.d.dither_color.u8[1]=color.c1.color;
	  g.type=SPT_DITHER_COLOR;
	} else
	  g.type=SPT_COLOR;
	break;
      case SPT_TRANSFORM_ON:
      case SPT_TRANSFORM_OFF:
	Lex(cc); //Skip {
	if (LexExpressionI64(cc))
	  g.type=SPT_TRANSFORM_ON;
	else
	  g.type=SPT_TRANSFORM_OFF;
	break;
      case SPT_LINE:
      case SPT_ARROW:
      case SPT_PLANAR_SYMMETRY:
	Lex(cc); //Skip {
	g.type=type;
	LexD2I32(cc,&g.pp.x1);
	if (cc->token!=',')
	  LexExcept(cc,"Expecting ',' at ");
	Lex(cc); //Skip ,
	LexD2I32(cc,&g.pp.x2);
	break;
      case SPT_RECT:
      case SPT_ROTATED_RECT:
	Lex(cc); //Skip {
	LexD2I32(cc,&g.pp.x1);
	if (cc->token!=':')
	  LexExcept(cc,"Expecting ':' at ");
	Lex(cc); //Skip :
	LexD2I32(cc,&g.pp.x2);
	g.ppa.x2+=g.pp.x1;
	g.ppa.y2+=g.pp.y1;
	if (cc->token==',') {
	  Lex(cc); //Skip ,
	  g.ppa.angle=ã/180*LexExpressionF64(cc);
	  g.type=SPT_ROTATED_RECT;
	} else
	  g.type=SPT_RECT;
	break;
      case SPT_PT:
      case SPT_SHIFT:
	Lex(cc); //Skip {
	g.type=type;
	LexD2I32(cc,&g.p.x1);
	break;
      case SPT_FLOOD_FILL:
      case SPT_FLOOD_FILL_NOT:
	Lex(cc); //Skip {
	LexD2I32(cc,&g.p.x1);
	if (cc->token==',') {
	  Lex(cc); //Skip ,
	  i=LexExpressionI64(cc);
	} else
	  i=0;
	if (i)
	  g.type=SPT_FLOOD_FILL_NOT;
	else
	  g.type=SPT_FLOOD_FILL;
	break;
      case SPT_THICK:
	Lex(cc); //Skip {
	g.t.thick=LexExpressionI64(cc);
	g.type=SPT_THICK;
	break;
      case SPT_CIRCLE:
	Lex(cc); //Skip {
	g.type=SPT_CIRCLE;
	LexD2I32(cc,&g.pr.x1);
	if (cc->token!=':')
	  LexExcept(cc,"Expecting ':' at ");
	Lex(cc); //Skip :
	g.pr.radius=LexExpressionI64(cc);
	break;
      case SPT_POLYGON:
	Lex(cc); //Skip {
	g.pwhas.sides=LexExpressionI64(cc);
	if (cc->token!=',')
	  LexExcept(cc,"Expecting ',' at ");
      case SPT_ELLIPSE:
	Lex(cc); //Skip {
	g.type=type;
	LexD2I32(cc,&g.pwha.x1);
	if (cc->token!=':')
	  LexExcept(cc,"Expecting ':' at ");
	Lex(cc); //Skip :
	LexD2I32(cc,&g.pwha.width);
	if (cc->token!=',')
	  LexExcept(cc,"Expecting ',' at ");
	Lex(cc); //Skip ,
	g.pwha.angle=ã/180*LexExpressionF64(cc);
	break;
    end:
      size=SpriteElemSize(&g)+offset(CSprite.start);
      res=MAlloc(size);
      MemCpy(res,&g,size);
      break;
    case SPT_TEXT:
    case SPT_TEXT_BOX:
    case SPT_TEXT_DIAMOND:
      Lex(cc); //Skip {
      g.type=type;
      LexD2I32(cc,&g.ps.x1);
      if (cc->token!=',')
	LexExcept(cc,"Expecting ',' at ");
      if (Lex(cc)==TK_STR)  //Skip ,
	st=LexExtStr(cc);
      else
	LexExcept(cc,"Expecting string at ");
      size=SpriteElemQuedBaseSize(type);
      i=StrLen(st)+1;
      res=MAlloc(size+i);
      MemCpy(res,&g,size);
      MemCpy(res(U8 *)+size,st,i);
      Free(st);
      break;
    case SPT_POLYLINE:
      Lex(cc); //Skip {
      g.type=SPT_POLYLINE;
      QueInit(&headp);
      while (cc->token=='(') {
	tmpp=CAlloc(sizeof(CQueD3I32));
	LexD2I32(cc,&tmpp->p);
	QueIns(tmpp,headp.last);
	g.nu.num++;
	if (cc->token==',')
	  Lex(cc); //Skip ,
      }
      if (g.nu.num<2)
	LexExcept(cc,"Expecting point at ");
      size=SpriteElemQuedBaseSize(SPT_POLYLINE);
      res=MAlloc(size+g.nu.num*sizeof(CD2I32));
      MemCpy(res,&g,size);
      ptr=&res->nu.u;
      tmpp=headp.next;
      while (tmpp!=&headp) {
	tmpa1=tmpp->next;
	MemCpy(ptr,&tmpp->p,sizeof(CD2I32));
	ptr+=sizeof(CD2I32);
	Free(tmpp);
	tmpp=tmpa1;
      }
      break;
    case SPT_BSPLINE2:
    case SPT_BSPLINE3:
    case SPT_BSPLINE2_CLOSED:
    case SPT_BSPLINE3_CLOSED:
      Lex(cc); //Skip {
      QueInit(&headp);
      while (cc->token=='(') {
	tmpp=CAlloc(sizeof(CQueD3I32));
	LexD3I32(cc,&tmpp->p);
	QueIns(tmpp,headp.last);
	g.nu.num++;
	if (cc->token==',')
	  Lex(cc); //Skip ,
      }
      if (g.nu.num<2)
	LexExcept(cc,"Expecting point at ");
      size=SpriteElemQuedBaseSize(type);
      res=MAlloc(size+g.nu.num*sizeof(CD3I32));
      if (LexExpressionI64(cc)) {
	if (type==SPT_BSPLINE2||type==SPT_BSPLINE2_CLOSED)
	  g.type=SPT_BSPLINE2_CLOSED;
	else
	  g.type=SPT_BSPLINE3_CLOSED;
      } else {
	if (type==SPT_BSPLINE2||type==SPT_BSPLINE2_CLOSED)
	  g.type=SPT_BSPLINE2;
	else
	  g.type=SPT_BSPLINE3;
      }
      MemCpy(res,&g,size);
      ptr=&res->nu.u;
      tmpp=headp.next;
      while (tmpp!=&headp) {
	tmpa1=tmpp->next;
	MemCpy(ptr,&tmpp->p,sizeof(CD3I32));
	ptr+=sizeof(CD3I32);
	Free(tmpp);
	tmpp=tmpa1;
      }
      break;
    case SPT_POLYPT:
      Lex(cc); //Skip {
      LexD2I32(cc,&g.npu.x);
      if (cc->token!=',')
	LexExcept(cc,"Expecting ',' at ");
      tmpv=QueVectU8New;
      while (TRUE) {
	if (!(i=LexGetChar(cc)))
	  LexExcept(cc,"Expecting '}' at ");
	if (i=='}')
	  break;
	if ('0'<=i<='7')
	  QueVectU8Put(tmpv,g.npu.num++,i-'0');
      }
      Bts(&cc->flags,CCf_USE_LAST_U16);
      Lex(cc); //Load '}'
      g.type=SPT_POLYPT;
      size=SpriteElemQuedBaseSize(SPT_POLYPT);
      res=CAlloc(size+(g.npu.num*3+7)>>3);
      MemCpy(res,&g,size);
      ptr=&res->npu.u;
      for (i=0;i<g.npu.num;i++)
	BFieldOrU32(ptr,i*3,QueVectU8Get(tmpv,i));
      QueVectU8Del(tmpv);
      break;
    case SPT_BITMAP:
      Lex(cc); //Skip {
      LexD2I32(cc,&g.pwhu.x1);
      if (cc->token!=':')
	LexExcept(cc,"Expecting ':' at ");
      Lex(cc); //Skip :
      LexD2I32(cc,&g.pwhu.width);
      if (cc->token!=',')
	LexExcept(cc,"Expecting ',' at ");
      tmpv=QueVectU8New;
      num1=0;
      while (TRUE) {
	if (!(i=ToUpper(LexGetChar(cc))))
	  LexExcept(cc,"Expecting '}' at ");
	if (i=='}')
	  break;
	if ('0'<=i<='9')
	  QueVectU8Put(tmpv,num1++,i-'0');
	else if ('A'<=i<='F')
	  QueVectU8Put(tmpv,num1++,i-'A'+10);
	else if (i==CH_SPACE||i==CH_SHIFT_SPACE)
	  QueVectU8Put(tmpv,num1++,TRANSPARENT);
	else if (i=='_')
	  QueVectU8Put(tmpv,num1++,0);
      }
      Bts(&cc->flags,CCf_USE_LAST_U16);
      Lex(cc); //Load '}'
      g.type=SPT_BITMAP;
      size=SpriteElemQuedBaseSize(SPT_BITMAP);
      res=CAlloc(size+num1);
      MemCpy(res,&g,size);
      ptr=&res->pwhu.u;
      for (i=0;i<num1;i++)
	*ptr++=QueVectU8Get(tmpv,i);
      QueVectU8Del(tmpv);
      break;
    case SPT_MESH:
    case SPT_SHIFTABLE_MESH:
      Lex(cc); //Skip {
      if (LexExpressionI64(cc)) {
	g.type=SPT_SHIFTABLE_MESH;
	if (cc->token!=',')
	  LexExcept(cc,"Expecting ',' at ");
	Lex(cc); //Skip ,
	LexD3I32(cc,&g.pmu.x);
	if (cc->token!=':')
	  LexExcept(cc,"Expecting ':' at ");
	Lex(cc); //Skip :
      } else {
	g.type=SPT_MESH;
	if (cc->token!=',')
	  LexExcept(cc,"Expecting ',' at ");
	Lex(cc); //Skip ,
      }
      num1=0;
      QueInit(&headp);
      while (cc->token=='(') {
	tmpp=CAlloc(sizeof(CQueD3I32));
	LexD3I32(cc,&tmpp->p);
	QueIns(tmpp,headp.last);
	num1++;
	if (cc->token==',')
	  Lex(cc); //Skip ,
      }
      if (cc->token!=':')
	LexExcept(cc,"Expecting ':' at ");
      Lex(cc); //Skip :
      num2=0;
      QueInit(&headt);
      while (cc->token=='(') {
	tmpt=CAlloc(sizeof(CQueMeshTri));
	st=LexFirstRem(cc,",");
	tmpt->color=Str2ColorU32(st);
	Free(st);
	Lex(cc); //Skip color
	if (cc->token!=',')
	  LexExcept(cc,"Expecting ',' at ");
	Lex(cc); //Skip ,
	tmpt->nums[0]=LexExpressionI64(cc);
	if (cc->token!=',')
	  LexExcept(cc,"Expecting ',' at ");
	Lex(cc); //Skip ,
	tmpt->nums[1]=LexExpressionI64(cc);
	if (cc->token!=',')
	  LexExcept(cc,"Expecting ',' at ");
	Lex(cc); //Skip ,
	tmpt->nums[2]=LexExpressionI64(cc);
	if (cc->token!=')')
	  LexExcept(cc,"Expecting ')' at ");
	Lex(cc); //Skip )
	QueIns(tmpt,headt.last);
	num2++;
	if (cc->token==',')
	  Lex(cc); //Skip ,
      }
      if (g.type==SPT_MESH) {
	g.mu.vertex_cnt=num1;
	g.mu.tri_cnt=num2;
	size=SpriteElemQuedBaseSize(SPT_MESH);
      } else {
	g.pmu.vertex_cnt=num1;
	g.pmu.tri_cnt=num2;
      }
      size=SpriteElemQuedBaseSize(g.type);
      res=MAlloc(size+num1*sizeof(CD3I32)+num2*sizeof(CMeshTri));
      MemCpy(res,&g,size);
      ptr=res(U8 *)+size;
      tmpp=headp.next;
      while (tmpp!=&headp) {
	tmpa1=tmpp->next;
	MemCpy(ptr,&tmpp->p,sizeof(CD3I32));
	ptr+=sizeof(CD3I32);
	Free(tmpp);
	tmpp=tmpa1;
      }
      tmpt=headt.next;
      while (tmpt!=&headt) {
	tmpt1=tmpt->next;
	MemCpy(ptr,&tmpt->start,sizeof(CMeshTri));
	ptr+=sizeof(CMeshTri);
	Free(tmpt);
	tmpt=tmpt1;
      }
      break;
  }
  if (cc->token!='}')
    LexExcept(cc,"Expecting '}' at ");
  if (Lex(cc)!=';')
    LexExcept(cc,"Expecting ';' at ");
  return res;
}

public U8 *Code2Sprite(CDoc *doc,I64 *_size=NULL)
{//Text to sprite.
  CSprite head;
  U8 *res;
  Bool okay=TRUE,unlock_doc=DocLock(doc);
  CCmpCtrl *cc=CmpCtrlNew(,CCF_DONT_FREE_BUF);
  CHashTable *old_hash_table_lst=cc->htc.hash_table_lst;
  CHashGeneric *tmph;
  I64 i,size=0;
  QueInit(&head);
  LexAttachDoc(cc,,doc);
  try {
    do {
      cc->htc.hash_table_lst=NULL;
      if (Lex(cc)==TK_IDENT && //Skip ;
	    (tmph=HashFind(cc->cur_str,gr.sprite_hash,SPHT_ELEM_CODE))) {
	i=tmph->user_data0;
	cc->htc.hash_table_lst=old_hash_table_lst;
	if (Lex(cc)=='{') //Skip ident
	  QueIns(Code2SpriteElem(cc,i),head.last);
      } else if (cc->token)
	LexExcept(cc,"Expecting sprite element type name at ");
    } while (cc->token);
    okay=TRUE;
  } catch {
    Fs->catch_except=TRUE;
    okay=FALSE;
  }
  if (unlock_doc)
    DocUnlock(doc);
  if (okay) {
    CmpCtrlDel(cc); //TODO: can crash
    res=SpriteQue2Sprite(&head,&size);
  } else {
    res=NULL;
    size=0;
  }
  if (_size) *_size=size;
  QueDel(&head);
  return res;
}
