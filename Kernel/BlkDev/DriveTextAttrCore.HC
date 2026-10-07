U8 blkdev_text_attr[BDT_TYPES_NUM]={BLACK,LTCYAN,WHITE,LTGREEN,LTRED,LTBLUE};
U8 drv_text_attr[3]={BLACK,BLUE,RED};

U8 DrvTextAttrGet(U8 drv_let=0)
{//Get color of drive.
  drv_let=Let2Let(drv_let);
  if ('A'<=drv_let<='Z')
    return blkdev_text_attr[Let2BlkDevType(drv_let)]<<4|
	  drv_text_attr[drv_let%sizeof(drv_text_attr)];
  else
    return BLACK<<4|WHITE;
}

