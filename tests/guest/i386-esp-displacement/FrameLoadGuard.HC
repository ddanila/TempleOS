I64 FrameLoadGuardContract()
{
 CIntermediateCode *address=CAlloc(sizeof(CIntermediateCode)),*load=CAlloc(sizeof(CIntermediateCode));
 CI386Logic *logic=CAlloc(sizeof(CI386Logic));
 CHashClass *type=cmp.internal_types[RT_U8],*fake=CAlloc(2*sizeof(CHashClass));
 I64 mask=0,i,raw;
 address->ic_code=IC_ADD;address->ic_class=type+1;address->next=load;
 load->ic_code=IC_DEREF;load->ic_class=type;load->t.arg1_tree=address;
 if(I386FrameLoadEnd(address,NULL)==load)mask|=1;
 i=!I386FrameLoadEnd(NULL,NULL);address->ic_code=IC_SUB;i&=!I386FrameLoadEnd(address,NULL);address->ic_code=IC_ADD;
 address->ic_flags=1;i&=!I386FrameLoadEnd(address,NULL);address->ic_flags=0;if(i)mask|=2;
 address->next=NULL;i=!I386FrameLoadEnd(address,NULL);address->next=load;
 load->ic_code=IC_ADDR;i&=!I386FrameLoadEnd(address,NULL);load->ic_code=IC_DEREF;if(i)mask|=4;
 load->ic_flags=1;if(!I386FrameLoadEnd(address,NULL))mask|=8;load->ic_flags=0;
 load->t.arg1_tree=NULL;if(!I386FrameLoadEnd(address,NULL))mask|=16;load->t.arg1_tree=address;
 address->ic_class=NULL;i=!I386FrameLoadEnd(address,NULL);address->ic_class=type+1;
 load->ic_class=NULL;i&=!I386FrameLoadEnd(address,NULL);load->ic_class=cmp.internal_types[RT_U16];
 i&=!I386FrameLoadEnd(address,NULL);load->ic_class=type;address->ic_class=type;
 i&=!I386FrameLoadEnd(address,NULL);address->ic_class=type+1;if(i)mask|=32;
 fake->raw_type=RT_F32;fake->size=4;fake[1].ptr_stars_cnt=1;
 address->ic_class=fake+1;load->ic_class=fake;i=!I386FrameLoadEnd(address,NULL);
 fake->raw_type=RT_U64;fake->size=16;i&=!I386FrameLoadEnd(address,NULL);
 fake->size=8;fake[1].type=HTT_FUN;i&=!I386FrameLoadEnd(address,NULL);fake[1].type=0;
 fake->type=HTT_FUN;i&=!I386FrameLoadEnd(address,NULL);fake->type=0;
 address->ic_class=type+1;load->ic_class=type;if(i)mask|=64;
 i=TRUE;
 for(raw=RT_I8;raw<=RT_RTS_NUM;raw++) {
   if(raw<=RT_U64 || raw==RT_F64 || raw==RT_RTS_NUM) {
     if(raw==RT_RTS_NUM)load->ic_class=type+1;else load->ic_class=cmp.internal_types[raw];
     address->ic_class=load->ic_class+1;
     i&=I386FrameLoadEnd(address,NULL)==load;
   }
 }
 address->ic_class=type+1;load->ic_class=type;
 load->ic_flags=ICF_PUSH_RES;i&=I386FrameLoadEnd(address,NULL)==load;
 load->ic_flags=ICF_BY_VAL;i&=I386FrameLoadEnd(address,NULL)==load;
 load->ic_flags=ICF_PUSH_RES|ICF_BY_VAL;i&=I386FrameLoadEnd(address,NULL)==load;
 load->ic_flags=ICF_RES_TO_INT;i&=!I386FrameLoadEnd(address,NULL);
 load->ic_flags=ICF_PUSH_CMP;i&=!I386FrameLoadEnd(address,NULL);
 load->ic_flags=ICF_POP_CMP;i&=!I386FrameLoadEnd(address,NULL);
 load->ic_flags=ICF_PASS_TRACE;i&=!I386FrameLoadEnd(address,NULL);
 load->ic_flags=0;if(i)mask|=128;
 address->ic_class=type+1;load->ic_class=type;
 logic->left=address;i=!I386FrameLoadEnd(address,logic);logic->left=NULL;
 logic->end=address;i&=!I386FrameLoadEnd(address,logic);logic->end=NULL;
 logic->left=load;i&=I386FrameLoadEnd(address,logic)==load;logic->left=NULL;
 logic->end=load;i&=I386FrameLoadEnd(address,logic)==load;if(i)mask|=256;
 if(address->next==load && load->t.arg1_tree==address && !address->ic_flags && !load->ic_flags)mask|=512;
 Free(fake);Free(logic);Free(load);Free(address);return mask;
}
I64 frame_load_guard_mask=FrameLoadGuardContract;
U8 *frame_load_guard_line=MStrPrint("OBS FRAME LOAD GUARD %d\n",frame_load_guard_mask);
EspReport(frame_load_guard_line);Free(frame_load_guard_line);EspReport("DONE ESP encoding\n");
