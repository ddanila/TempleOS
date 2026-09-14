I64 SymbolSeedCheck(CHashClass *classes,CHashFun *functions,I64 pointer_bytes)
{
  I64 i;
  for(i=0;i<=PTR_STARS_NUM;i++) {
    if(classes[i].type!=HTT_CLASS || functions[i].type!=HTT_FUN ||
        classes[i].raw_type!=RT_PTR || functions[i].raw_type!=RT_PTR ||
        classes[i].ptr_stars_cnt!=i || functions[i].ptr_stars_cnt!=i) return 1;
    if(i) {
      if(classes[i].size!=pointer_bytes || functions[i].size!=pointer_bytes ||
          classes[i].last_in_member_lst || functions[i].last_in_member_lst) return 2;
    } else if(classes[i].size || functions[i].size ||
        classes[i].last_in_member_lst!=&classes[i].member_lst_and_root ||
        functions[i].last_in_member_lst!=&functions[i].member_lst_and_root) return 3;
    if(classes[i].str || classes[i].next || classes[i].flags || classes[i].neg_offset ||
        classes[i].member_cnt || classes[i].base_class || classes[i].fwd_class ||
        classes[i].member_lst_and_root || classes[i].member_class_base_root ||
        classes[i].src_link || classes[i].dbg_info || classes[i].idx ||
        classes[i].import_name || classes[i].ie_lst ||
        functions[i].return_class || functions[i].arg_cnt || functions[i].exe_addr ||
        functions[i].ext_lst || functions[i].flags || functions[i].used_reg_mask ||
        functions[i].clobbered_reg_mask || functions[i].member_lst_and_root ||
        functions[i].member_class_base_root) return 4;
    if(classes+i-classes[i].ptr_stars_cnt!=classes ||
        functions+i-functions[i].ptr_stars_cnt!=functions) return 5;
  }
  return 0;
}
