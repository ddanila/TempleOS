U0 InFile(U8 *filename)
{//Send InFile code file to self.
  U8 *name=ExtDft(filename,"IN.Z");
  InStr("Cd(\"%C:%s\");;#include \"%s\"",
	Drv2Let(Fs->cur_dv),Fs->cur_dir,name);
  Free(name);
}

