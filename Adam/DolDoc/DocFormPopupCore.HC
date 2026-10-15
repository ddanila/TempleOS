public Bool PopUpForm(U8 *_d,U8 *class_name=lastclass,
	I64 dof_flags=DOF_SIZE_MIN,U8 *header=NULL,U8 *footer=NULL)
{//See $LK,"::/Demo/DolDoc/Form.HC"$ and $LK,"::/Demo/LastClass.HC"$.
  return PopUpPrint("DocForm(0x%X,0x%X,0x%X,0x%X,0x%X);",_d,class_name,
	dof_flags,header,footer);
}
