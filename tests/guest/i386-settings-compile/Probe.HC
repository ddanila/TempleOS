//Compile-only dependency probe: never silently replace the autocomplete service.
Bool AutoComplete(Bool val=OFF)
{ no_warn val;throw('Missing',TRUE);return FALSE; }
#include "/Probe/TaskSettingsCore.HC"
