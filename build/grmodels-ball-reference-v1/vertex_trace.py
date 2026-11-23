from pathlib import Path
import struct


def instrument(source):
    trace_declarations = b'I64 ball_vertex_trace[768];\nI64 ball_vertex_calls;\n\n'
    marker = b'I64 AddVertex(BallDefineStruct *,I64 x,I64 y,I64 z)\n{\n  I64 i;\n'
    if source.count(marker) != 1:
        raise ValueError('AddVertex signature changed')
    log = b'''  if (ball_vertex_calls<256) {
    ball_vertex_trace[ball_vertex_calls*3]=x;
    ball_vertex_trace[ball_vertex_calls*3+1]=y;
    ball_vertex_trace[ball_vertex_calls*3+2]=z;
    ball_vertex_calls++;
  }
'''
    return trace_declarations + source.replace(marker, marker + log)


def observe(fixture):
    marker = b'  BallUILog(line);\n  Sleep(2000);'
    if fixture.count(marker) != 1:
        raise ValueError('Mesh export block changed')
    fixture = fixture.replace(b'  sprite=BallGen;', b'  ball_vertex_calls=0;\n  sprite=BallGen;')
    return fixture.replace(marker, b'''  BallUILog(line);
  if (ball_vertex_calls!=256) {
    StrPrint(line,"FAIL BallGen AddVertex call count %d\\n",ball_vertex_calls);
    BallUILog(line);
  } else {
    StrPrint(line,"EXPORT BallVertexCalls.bin %X 1800\\n",ball_vertex_trace);
    BallUILog(line);
  }
  Sleep(2000);''')


def read(directory):
    data = (Path(directory) / 'guest/BallVertexCalls.bin').read_bytes()
    if len(data) != 256 * 24:
        raise ValueError('Unexpected number of AddVertex calls')
    return list(struct.iter_unpack('<3q', data))
