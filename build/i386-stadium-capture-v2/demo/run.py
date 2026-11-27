from pathlib import Path
import hashlib,json,runpy,subprocess,sys,time

out=Path(__file__).resolve().parent
native=sys.argv[1]=='native'
mode='native' if native else 'original'
source=Path('Demo/Games/Stadium/StadiumGen.HC')
sha=lambda x:hashlib.sha256(x).hexdigest()
fixture=(out/'StadiumCheck.HC').read_bytes()
Guest=runpy.run_path('tools/test-i386-autocomplete-interaction.py')['Guest']
if native:
    disk=out.parent/'cross/kernel.img'
    pack=runpy.run_path('tools/package-i386-native-image.py')
    assert pack['snapshot'](disk.read_bytes())[1]['/'+source.as_posix()][2]==source.read_bytes()
    image=out/'working.img'
    pack['package'](disk,image,additions={'/Probe/StadiumCheck.HC':fixture})
else:
    overlay=out/'original-source'
    overlay.mkdir()
    pinned=runpy.run_path('tools/test-i386-timeclock-reference.py')['restore_reference'](overlay)
    assert pinned[source.as_posix()]==sha(source.read_bytes())
    (overlay/'Once.HC').write_bytes(fixture)
    image=out/'original.iso'
    subprocess.run([sys.executable,'tools/build-iso.py','--overlay',str(overlay),'--output',str(image)],check=True)
guest=Guest(image,out/mode,native,reference_cpus=1)
report=dict(source_sha256=sha(source.read_bytes()),image_sha256=sha(image.read_bytes()),
            scope='Unmodified Stadium background generator in writable scratch with saved image readback')
try:
    if native:
        guest.wait('DONE native kernel startup\n')
        guest.command('#include "C:/Probe/StadiumCheck.HC"')
        guest.command('CDC *st_check=DCScrnCapture(FALSE,Fs);')
        guest.command("if(!st_check||st_check->mem_task!=Fs||st_check->width!=640||st_check->height!=480)throw('StadDC',TRUE);")
        guest.command('DCDel(st_check);')
        report['explicit_task_capture']=True
    else:
        guest.wait('STADIUM READY\n')
        time.sleep(2)
    offset=len(guest.collect())
    drive,target=('C','C:/StadiumCheck') if native else ('T','B:/StadiumCheck')
    guest.type(f'StadiumCheck("{drive}:/Demo/Games/Stadium","{target}");')
    guest.press('ret')
    guest.wait('STADIUM GENERATOR DONE\n',90,offset)
    data=(guest.out/'stadium.raw').read_bytes()
    colors=sorted(set(data))
    assert len(data)%473==0 and 641<=len(data)//473<=656 and len(colors)>2
    report.update(result='pass',bitmap_sha256=sha(data),size=len(data),width=641,
                  stored_width=len(data)//473,height=473,colors=colors)
    if native:
        guest.wait('COMMAND OK\n',30,offset)
        guest.command('6*7;')
        report['fresh_arithmetic']=guest.result_pixels()
except Exception as e:
    report.update(result='fail',error=str(e))
    raise
finally:
    guest.close()
    (out/(mode+'-result.json')).write_text(json.dumps(report,indent=2)+'\n')
