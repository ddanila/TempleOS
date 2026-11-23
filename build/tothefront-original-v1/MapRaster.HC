U0 TTFExportMap()
{
  U8 line[160];
  StrPrint(line,"TTF map size %d %d %d %d %d\n",
      map_dc->width,map_dc->height,map_dc->width_internal,map_rows,map_cols);
  TTFPhaseLog(line);
  StrPrint(line,"EXPORT map-pixels.bin %X %X\n",
      map_dc->body,map_dc->width_internal*map_dc->height);
  TTFPhaseLog(line);
  StrPrint(line,"EXPORT terrain.bin %X %X\n",terrain,map_rows*map_cols);
  TTFPhaseLog(line);
  StrPrint(line,"EXPORT rivers.bin %X %X\n",rivers,map_rows*map_cols);
  TTFPhaseLog(line);
  StrPrint(line,"EXPORT roads.bin %X %X\n",roads,map_rows*map_cols);
  TTFPhaseLog(line);
  TTFPhaseLog("TTF map exported\n");
}
