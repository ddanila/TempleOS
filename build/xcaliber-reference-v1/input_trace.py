"""Trace the real X-Caliber key loop and teardown."""

def instrument(source):
    helper = b'''U0 XCInputLog(U8 *p)
{
  while (*p) OutU8(0xE9,*p++);
}

U0 XCInputKey(I64 code,I64 ch,I64 sc)
{
  U8 data[128];
  StrPrint(data,"XC key %d %d %X\\n",code,ch,sc);
  XCInputLog(data);
}

'''
    key_loop = b'\tswitch (msg_code) {'
    teardown = b'    AllDel(ode);'
    for marker in (key_loop, teardown):
        if source.count(marker) != 1:
            raise ValueError(f'Missing unique X-Caliber trace location {marker!r}')
    source = source.replace(key_loop, b'        XCInputKey(msg_code,arg1,arg2);\n' + key_loop)
    source = source.replace(teardown, b'    XCInputLog("XC before teardown\\n");\n' + teardown
                            + b'\n    XCInputLog("XC after teardown\\n");')
    return helper + source
