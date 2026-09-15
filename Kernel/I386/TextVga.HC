#include "/Kernel/I386/TextVga.HH"
#include "/Kernel/I386/Vga.HH"
public I64 I386TextPresent(CI386Text *text)
{//The caller exclusively owns both the text record and VGA access.
  I64 rows;
  if(!text || !text->planes) return -1;
  if(text->dirty_first==60 && !text->dirty_last) return 0;
  if(text->dirty_first>=text->dirty_last || text->dirty_last>60) return -1;
  rows=text->dirty_last-text->dirty_first;
  if(!I386VgaRows(text->planes,text->dirty_first*8,rows*8)) return -1;
  text->dirty_first=60; text->dirty_last=0;
  return rows;
}
