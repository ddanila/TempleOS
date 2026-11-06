public I8 Note2Ona(I64 note,I64 octave=4)
{//Note to ona. Mid C is ona=51, note=3 and octave=4.
  if (note<3)
    return (octave+1)*12+note;
  else
    return octave*12+note;
}

public I8 Ona2Note(I8 ona)
{//Ona to note in octave. Mid C is ona=51, note=3 and octave=4.
  return ona%12;
}

public I8 Ona2Octave(I8 ona)
{//Ona to octave. Mid C is ona=51, note=3 and octave=4.
  I64 note=ona%12,octave=ona/12;
  if (note<3)
    return octave-1;
  else
    return octave;
}

