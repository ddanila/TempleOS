#include "::/Demo/ToHtmlToTXTDemo/ToHtml.HC"
U8 *TestConvertLink(U8 *link)
{
  if (StrCmp(link,"FI:::/Doc/DolDocOverview.DD"))
    throw('BadLink',TRUE);
  return StrNew("converted/overview.html");
}
U0 ConvertFixture()
{
  U8 *sample="$$LK,\"Overview\",A=\"FI:::/Doc/DolDocOverview.DD\"$$\n";
  FileWrite("~/LinkSample.DD",sample,StrLen(sample));
  ToHtml("~/LinkSample.DD","~/DemoOutPage",NULL,NULL,NULL,NULL,80,TRUE,&TestConvertLink);
}
ConvertFixture;
