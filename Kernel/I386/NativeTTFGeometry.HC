#include "/Adam/Gr/Gr.HH"
#include "/Adam/Gr/GrBlotCore.HC"
#include "/Adam/Gr/GrPixelCoverageCore.HC"

Bool IsPixCovered0(CTask *task,I64 x,I64 y) {return GrPixelCoveredCore(task,x,y);}

#include "/Adam/Gr/GrLineWalkCore.HC"
#include "/Adam/Gr/GrPlotCore.HC"
#include "/Adam/Gr/GrPeekCore.HC"
