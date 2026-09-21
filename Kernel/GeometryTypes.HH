#ifndef GEOMETRY_TYPES_INCLUDED
#define GEOMETRY_TYPES_INCLUDED
#help_index "Graphics/Data Types/D3I32;Math/Data Types/D3I32;Data Types/D3I32"
public class CD3I32 //Three dimensional I32 pt
{
  I32	x,y,z;
};
public class CQueD3I32 //Que of three dimensional I32 pts
{
  CQueD3I32	*next,*last;
  CD3I32	p;
};
#help_index "Math/Data Types;Data Types"
public class CD2I32 //Two dimensional I32 pt
{
  I32	x,y;
};
public class CD2I64 //Two dimensional I64 pt
{
  I64	x,y;
};
public class CD3I64 //Three dimensional I64 pt
{
  I64	x,y,z;
};
public class CD2 //Two dimensional F64 pt
{
  F64	x,y;
};

#help_index "Math/CD3;Data Types/CD3"
public class CD3 //Three dimensional F64 pt
{
  F64	x,y,z;
};

#endif
