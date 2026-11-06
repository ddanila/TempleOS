class UniqueModuleClassName {I64 value;};
U8 *Inferred(U8 *data,U8 *name=lastclass) {return name;}
U8 *Explicit(U8 *text="module-default-string-value") {return text;}
public U8 *ClassName() {UniqueModuleClassName item;return Inferred(&item);}
public U8 *DefaultText() {return Explicit();}
