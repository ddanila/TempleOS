CIntermediateCode *OptFree(CCmpCtrl *cc,CIntermediateCode *tmpi)
{//We might access freed entries in CICTreeLinks
  ICDetach(tmpi);
  Free(tmpi);
  return NULL;
}
