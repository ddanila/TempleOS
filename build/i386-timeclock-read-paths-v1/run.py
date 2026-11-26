import sys
from pathlib import Path

tool = Path('tools/test-i386-timeclock-report-native.py').resolve()
fixture = Path(__file__).with_name('Contract.HC').resolve()
source = tool.read_text()
source = source.replace("FIXTURE = ROOT/'tests/guest/i386-timeclock-report-native/Contract.HC'",
                        f"FIXTURE = Path({str(fixture)!r})")
assert str(fixture) in source
archive = Path(__file__).with_name('Archive.DATA').resolve()
source = source.replace("additions={'/ReportNative.HC':FIXTURE.read_bytes()}",
                        "additions={'/ReportNative.HC':FIXTURE.read_bytes(), "
                        + f"'/Archive.DATA':Path({str(archive)!r}).read_bytes()" + "}")
sys.argv[0] = str(tool)
exec(compile(source,str(tool),'exec'),{'__file__':str(tool),'__name__':'__main__'})
