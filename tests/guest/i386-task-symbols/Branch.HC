//Execute the production branch optimizer on native owned IR, in both IF states.
I64 CodeBranchTest()
{
  CCmpCtrl *cc,*other;
  CHashClass type;
  CIntermediateCode *left,*right,*predicate,*previous,*branch,*result,*split1,*split2;
  CIntermediateCode *removed[4];
  CCodeMisc *target,*fallthrough;
  I64 enabled,polarity,opcode,inversions,i,expected,used=heap.used,allocations=heap.allocations;
  I64 base_used,base_allocations,kind;
  U32 flags=GetRFlags;
  type.raw_type=RT_I64; type.fwd_class=0;
  for(enabled=0;enabled<2;enabled++) {
    SetRFlags((flags&~0x200)|(enabled*0x200));
    cc=I386TaskCmpCtrlNew(&task_compiler,"branches",CCF_DONT_FREE_BUF);
    other=I386TaskCmpCtrlNew(&task_compiler,"foreign",CCF_DONT_FREE_BUF);
    if(!cc || !other) return 120;
    branch=I386ICAdd(&heap,other,IC_BR_ZERO,0,&type);
    if(!branch || I386OptBranch(&heap,cc,branch) || I386OptBranch(&heap,cc,0) ||
        I386OptBranch(&heap,cc,&cc->coc.coc_head) || !I386CmpCtrlDel(&heap,other)) return 121;
    base_used=heap.used; base_allocations=heap.allocations;
    for(polarity=0;polarity<2;polarity++)
      for(opcode=IC_EQU_EQU;opcode<=IC_LESS_EQU;opcode++)
        for(inversions=0;inversions<4;inversions++) {
          target=I386COCMiscNew(&heap,cc,CMT_LABEL);
          left=I386ICAdd(&heap,cc,IC_IMM_I64,0xFEDCBA9876543210,&type);
          right=I386ICAdd(&heap,cc,IC_IMM_I64,0x123456789ABCDEF0,&type);
          predicate=I386ICAdd(&heap,cc,opcode,0,&type,ICF_LOCK);
          if(!target || !left || !right || !predicate) return 122;
          predicate->t.arg1_tree=left; predicate->t.arg2_tree=right;
          predicate->t.arg1_class=predicate->t.arg2_class=&type;
          previous=predicate; removed[0]=predicate;
          for(i=0;i<inversions;i++) {
            result=I386ICAdd(&heap,cc,IC_NOT,0,&type);
            if(!result) return 123;
            result->t.arg1_tree=previous; result->t.arg1_class=&type;
            removed[i+1]=result; previous=result;
          }
          expected=IC_BR_ZERO; if(polarity) expected=IC_BR_NOT_ZERO;
          branch=I386ICAdd(&heap,cc,expected,target,&type);
          if(!branch || I386OptBranch(&heap,cc,left)) return 124;
          result=I386OptBranch(&heap,cc,branch);
          expected=opcode-IC_EQU_EQU;
          if(!(polarity^(inversions&1))) expected^=1;
          expected+=IC_BR_EQU_EQU;
          if(result!=branch || branch->ic_code!=expected || branch->ic_data!=target ||
              branch->ic_class!=&type || !(branch->ic_flags&ICF_LOCK) ||
              branch->t.arg1_tree!=left || branch->t.arg2_tree!=right ||
              cc->coc.coc_head.next!=left || left->next!=right || right->next!=branch ||
              branch->last!=right || branch->next!=&cc->coc.coc_head ||
              cc->coc.coc_head.last!=branch) return 125;
          for(i=0;i<=inversions;i++)
            if(I386HeapSize(&heap,removed[i])<sizeof(CIntermediateCode) ||
                I386ICRetire(&heap,cc,removed[i])) return 126;
          if(predicate->ic_code!=opcode || predicate->t.arg1_tree->ic_data!=0xFEDCBA9876543210 ||
              !I386COCDiscard(&heap,cc) || heap.used!=base_used || heap.allocations!=base_allocations) return 127;
        }
    for(polarity=0;polarity<2;polarity++)
      for(kind=0;kind<2;kind++) {
        target=I386COCMiscNew(&heap,cc,CMT_LABEL);
        left=I386ICAdd(&heap,cc,IC_IMM_I64,1,&type);
        split1=I386ICAdd(&heap,cc,IC_NOP1,0,&type);
        right=I386ICAdd(&heap,cc,IC_IMM_I64,2,&type);
        split2=I386ICAdd(&heap,cc,IC_NOP1,0,&type);
        opcode=IC_AND_AND; if(kind) opcode=IC_OR_OR;
        predicate=I386ICAdd(&heap,cc,opcode,0,&type);
        expected=IC_BR_ZERO; if(polarity) expected=IC_BR_NOT_ZERO;
        branch=I386ICAdd(&heap,cc,expected,target,&type);
        if(!target || !left || !split1 || !right || !split2 || !predicate || !branch) return 128;
        predicate->t.arg1_tree=left; predicate->t.arg2_tree=right;
        predicate->t.arg1_class=predicate->t.arg2_class=&type;
        result=I386OptBranch(&heap,cc,branch);
        if(result!=split2 || split2->ic_code!=expected || split2->ic_data!=target ||
            split1->t.arg1_tree!=left || split2->t.arg1_tree!=right ||
            split2->next!=branch || branch->last!=split2 ||
            predicate->t.arg2_tree!=right || I386HeapSize(&heap,predicate)<sizeof(CIntermediateCode)) return 129;
        if(kind==polarity) {
          if(branch->ic_code!=IC_NOP1 || split1->ic_code!=expected || split1->ic_data!=target ||
              cc->coc.coc_last_misc!=target) return 130;
        } else {
          fallthrough=branch->ic_data;
          opcode=IC_BR_NOT_ZERO; if(polarity) opcode=IC_BR_ZERO;
          if(branch->ic_code!=IC_LABEL || fallthrough==target ||
              cc->coc.coc_last_misc!=fallthrough || fallthrough->type!=CMT_LABEL ||
              split1->ic_code!=opcode || split1->ic_data!=fallthrough) return 131;
        }
        if(!I386COCDiscard(&heap,cc) || heap.used!=base_used || heap.allocations!=base_allocations) return 132;
      }
    //Carry/bit-test calls become branch intrinsics, retaining CALL_END2.
    for(polarity=0;polarity<2;polarity++)
      for(kind=0;kind<8;kind++) {
        switch(kind) {
          case 0: opcode=IC_CARRY; expected=IC_BR_CARRY; break;
          case 1: opcode=IC_BT; expected=IC_BR_BT; break;
          case 2: opcode=IC_BTS; expected=IC_BR_BTS; break;
          case 3: opcode=IC_BTR; expected=IC_BR_BTR; break;
          case 4: opcode=IC_BTC; expected=IC_BR_BTC; break;
          case 5: opcode=IC_LBTS; expected=IC_BR_BTS; break;
          case 6: opcode=IC_LBTR; expected=IC_BR_BTR; break;
          case 7: opcode=IC_LBTC; expected=IC_BR_BTC; break;
        }
        if(!polarity) { if(kind) expected+=IC_BR_NOT_BT-IC_BR_BT; else expected++; }
        target=I386COCMiscNew(&heap,cc,CMT_LABEL);
        predicate=I386ICAdd(&heap,cc,opcode,0,&type);
        previous=I386ICAdd(&heap,cc,IC_CALL_END,0,&type);
        opcode=IC_BR_ZERO; if(polarity) opcode=IC_BR_NOT_ZERO;
        branch=I386ICAdd(&heap,cc,opcode,target,&type);
        if(!target || !predicate || !previous || !branch ||
            I386OptBranch(&heap,cc,branch)!=previous || predicate->ic_code!=expected ||
            predicate->ic_data!=target || previous->ic_code!=IC_CALL_END2 || branch->ic_code!=IC_NOP1 ||
            (kind>=5 && !(predicate->ic_flags&ICF_LOCK)) ||
            cc->coc.coc_head.next!=predicate || predicate->next!=previous || previous->next!=branch ||
            !I386COCDiscard(&heap,cc) || heap.used!=base_used || heap.allocations!=base_allocations) return 134;
      }
    if(!I386CmpCtrlDel(&heap,cc) || heap.used!=used || heap.allocations!=allocations ||
        (GetRFlags&0x200)!=(enabled*0x200) || !I386HeapValid(&heap)) return 133;
  }
  SetRFlags(flags); return 0;
}
