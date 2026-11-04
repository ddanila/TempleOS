I64 KbdMsEvtTime()
{//Timestamp of last key or mouse event.
  if (ms_hard.timestamp>kbd.timestamp)
    return ms_hard.timestamp;
  else
    return kbd.new_key_timestamp;
}
