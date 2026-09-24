#!/usr/bin/env python3
"""Three-boot acceptance for native DolDoc creation, replacement, and reopen."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy
import shutil
import struct

ROOT=Path(__file__).resolve().parents[1]
INPUT=runpy.run_path(str(ROOT/'tools/i386-kernel-input.py'))['run_input']


def verify_redsea_project(disk):
    """Walk the persisted volume without guest code and audit extent ownership."""
    image=disk.read_bytes()
    start=2048
    if len(image)<(start+1)*512: raise ValueError('RedSea header is outside disk')
    volume_start,sectors,root,bitmap_blocks,version=struct.unpack_from('<5q',image,start*512+8)
    end=start+sectors; first=start+bitmap_blocks+1
    header=image[start*512:(start+1)*512]
    if (header[3]!=0x88 or header[510:512]!=b'\x55\xaa' or
        volume_start!=start or version!=1 or root<first or root>=end or
        end*512>len(image)):
        raise ValueError('Invalid persisted RedSea header')
    owned=set(); files={}; directories=set(); visiting=set()
    def claim(block,size):
        count=(size+511)//512
        if size<=0 or block<first or block+count>end: raise ValueError('Invalid persisted extent')
        for sector in range(block,block+count):
            if sector in owned: raise ValueError('Overlapping persisted extents')
            owned.add(sector)
    def record(offset):
        attr,raw_name,block,size,date=struct.unpack_from('<H38sqqQ',image,offset)
        name=raw_name.split(b'\0',1)[0].decode('ascii')
        return attr,name,block,size,date
    def directory(block,parent,path):
        if block in visiting: raise ValueError('Cyclic persisted directory tree')
        visiting.add(block)
        attr,name,self_block,size,date=record(block*512)
        if (attr,name,self_block,date)!=(0x810,'.',block,0) or size<512 or size%512:
            raise ValueError('Invalid persisted self entry')
        if record(block*512+64)!=(0x810,'..',parent,0,0):
            raise ValueError('Invalid persisted parent entry')
        claim(block,size); directories.add(path or '/')
        names=set(); terminated=False
        for offset in range(128,size,64):
            absolute=block*512+offset
            attr,name,child,length,date=record(absolute)
            if not name:
                if any(image[absolute:block*512+size]):
                    raise ValueError('Nonzero bytes after persisted directory terminator')
                terminated=True; break
            if attr&0x100:
                continue
            if date or name in names or name in ('.','..') or '/' in name:
                raise ValueError('Invalid persisted directory entry')
            names.add(name); child_path=(path+'/'+name) if path else '/'+name
            if attr==0x810:
                directory(child,block,child_path)
                if record(child*512)[3]!=length: raise ValueError('Persisted directory sizes disagree')
            elif attr==0x800:
                if length:
                    claim(child,length); content=image[child*512:child*512+length]
                elif child:
                    raise ValueError('Empty persisted file owns a block')
                else: content=b''
                files[child_path]=content
            else: raise ValueError('Invalid persisted attributes')
        if not terminated: raise ValueError('Missing persisted directory terminator')
        visiting.remove(block)
    directory(root,root,'')
    bitmap=image[(start+1)*512:first*512]
    for index in range(len(bitmap)*8):
        block=first-1+index
        expected=block<first or block>=end or block in owned
        if bool(bitmap[index//8]&(1<<(index&7)))!=expected:
            raise ValueError('Persisted bitmap disagrees with reachable extents')
    expected_dirs={'/Project','/Project/Sub'}
    if not expected_dirs<=directories: raise ValueError('Persisted project directories are missing')
    if '/Project/MoveMe' in directories or '/Project/Moved' in directories:
        raise ValueError('Renamed/deleted directory persisted unexpectedly')
    if files.get('/Project/Sub/Main.HC')!=b'7*7;\x05':
        raise ValueError('Persisted nested program bytes differ')
    if files.get('/Project/Sub/Relative.HC')!=b'8*8;\x05':
        raise ValueError('Persisted relative-path program bytes differ')
    if ('/Project/Sub/Temp.HC' in files or '/Project/Sub/Renamed.HC' in files or
        '/Project/Moved/Transferred.HC' in files):
        raise ValueError('Renamed/moved/deleted project fixture persisted unexpectedly')
    if files.get('/NativeColor.DD')!=(b'$FG,4$red$FG$ plain$BG,1$ blue$BG$ end'
                                      b'$IV,1$ inv$IV,0$$UL,1$ under$UL,0$ done\x05'):
        raise ValueError('Persisted color/style document bytes differ')
    if files.get('/NativeStyleKeys.DD')!=b'$UL,1$under$UL,0$ $IV,1$inv$IV,0$ done\x05':
        raise ValueError('Persisted keyboard-authored style bytes differ')
    if files.get('/NativeBlink.DD')!=b'$BK,1$blink$BK,0$ steady\x05':
        raise ValueError('Persisted keyboard-authored blink bytes differ')
    if files.get('/StandaloneEdit.DD')!=b'standalone\x05':
        raise ValueError('Persisted file-level editor bytes differ')
    return {'directories':len(directories),'files':len(files),'owned_sectors':len(owned),
            'project_path':'/Project/Sub/Main.HC','project_bytes':5,
            'relative_path':'/Project/Sub/Relative.HC','relative_bytes':5,
            'rename_delete_cycle':'old and new names absent after reboot',
            'file_move_cycle':'cross-directory bytes verified, destination deleted',
            'directory_cycle':'renamed directory verified after reboot, then deleted empty',
            'bitmap':'matches reachable extents'}


def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('disk',type=Path,nargs='?',default=ROOT/'build/i386-kernel/kernel.img')
    parser.add_argument('--out',type=Path,default=ROOT/'build/i386-doldoc-session')
    args=parser.parse_args()
    args.out.mkdir(parents=True,exist_ok=True)
    candidate=args.out/'session.img'
    shutil.copyfile(args.disk,candidate)
    source_hash=hashlib.sha256(args.disk.read_bytes()).hexdigest()
    result={'result':'incomplete','source_disk_sha256':source_hash,'candidate':str(candidate)}
    (args.out/'result.json').unlink(missing_ok=True)
    try:
        create={
          'status':'ok','answers':[],
          'commands':[
            ('CDoc *edit_doc=DocNew("C:/NativeEdit.DD",Fs);',[]),
            ('edit_doc!=0&&edit_doc->doc_signature==DOC_SIGNATURE_VAL;',['1']),
            ('DocEd(edit_doc);',['1'],{
              'begin':'DOC EDIT begin\n','end':'DOC EDIT end\n',
              'initial_rows':['TempleOS i386','DolDoc editor','C:/NativeEdit.DD','',
                              bytes([0xDB]).decode('cp437')],
              'events':[{'text':'abc'},{'key':'left'},{'key':'left'},
                        {'text':'X'},{'key':'backspace'},{'text':'Z'},
                        {'mark_log':'HELP VIEW begin\n'},{'key':'f1'},
                        {'wait_log_after':'HELP VIEW begin\n'},
                        {'mark_log':'HELP VIEW end\n'},{'key':'esc'},
                        {'wait_log_after':'HELP VIEW end\n'}],
              'final_rows':['TempleOS i386','DolDoc editor','C:/NativeEdit.DD','',
                            'aZ'+bytes([0xDB]).decode('cp437')+'bc'],
            }),
            ("I64 edit_size;U8 *edit_text=DocSave(edit_doc,&edit_size);edit_text[0]=='a'&&edit_text[1]=='Z'&&edit_text[2]==5&&edit_text[3]=='b'&&edit_text[4]=='c'&&edit_text[5]==0;",['1']),
            ('Free(edit_text);DocWrite(edit_doc);',['1']),
            ('CDoc *multi_doc=DocNew("C:/NativeMulti.DD",Fs);',[]),
            ('DocEd(multi_doc);',['1'],{
              'begin':'DOC EDIT begin\n','end':'DOC EDIT end\n',
              'initial_rows':['TempleOS i386','DolDoc editor','C:/NativeMulti.DD','',
                              bytes([0xDB]).decode('cp437')],
              'events':[{'text':'ab'},{'key':'ret'},{'text':'cd'}],
              'final_rows':['TempleOS i386','DolDoc editor','C:/NativeMulti.DD','',
                            'ab','cd'+bytes([0xDB]).decode('cp437')],
            }),
            ("I64 multi_size;U8 *multi_text=DocSave(multi_doc,&multi_size);multi_size==6&&multi_text[0]=='a'&&multi_text[1]=='b'&&multi_text[2]==10&&multi_text[3]=='c'&&multi_text[4]=='d'&&multi_text[5]==5;",['1']),
            ('Free(multi_text);DocEd(multi_doc);',['1'],{
              'begin':'DOC EDIT begin\n','end':'DOC EDIT end\n',
              'initial_rows':['TempleOS i386','DolDoc editor','C:/NativeMulti.DD','',
                              'ab','cd'+bytes([0xDB]).decode('cp437')],
              'events':[{'key':'left'},{'key':'left'},{'text':'X'},
                        {'key':'backspace'},{'key':'backspace'},{'text':'Z'}],
              'final_rows':['TempleOS i386','DolDoc editor','C:/NativeMulti.DD','',
                            'abZ'+bytes([0xDB]).decode('cp437')+'cd'],
            }),
            ("(multi_text=DocSave(multi_doc,&multi_size))&&multi_size==6&&multi_text[0]=='a'&&multi_text[1]=='b'&&multi_text[2]=='Z'&&multi_text[3]==5&&multi_text[4]=='c'&&multi_text[5]=='d';",['1']),
            ('Free(multi_text);',[]),
            ('DocWrite(multi_doc);',['1']),
            ('CDoc *nav_doc=DocNew("C:/NativeNavigation.DD",Fs);',[]),
            ('DocEd(nav_doc);',['1'],{
              'begin':'DOC EDIT begin\n','end':'DOC EDIT end\n',
              'initial_rows':['TempleOS i386','DolDoc editor','C:/NativeNavigation.DD','',
                              bytes([0xDB]).decode('cp437')],
              'events':[{'text':'abc'},{'key':'home'},{'key':'right'},
                        {'key':'delete'},{'key':'tab'},{'key':'end'},
                        {'key':'home'},{'key':'right'},{'key':'right'}],
              'final_rows':['TempleOS i386','DolDoc editor','C:/NativeNavigation.DD','',
                            'a       '+bytes([0xDB]).decode('cp437')+'c'],
            }),
            ("I64 nav_size;U8 *nav_text=DocSave(nav_doc,&nav_size);nav_size==4&&nav_text[0]=='a'&&nav_text[1]==9&&nav_text[2]==5&&nav_text[3]=='c';",['1']),
            ('Free(nav_text);DocWrite(nav_doc);',['1']),
            ('CDoc *vert_doc=DocNew("C:/NativeVertical.DD",Fs);',[]),
            ('DocEd(vert_doc);',['1'],{
              'begin':'DOC EDIT begin\n','end':'DOC EDIT end\n',
              'initial_rows':['TempleOS i386','DolDoc editor','C:/NativeVertical.DD','',
                              bytes([0xDB]).decode('cp437')],
              'events':[{'text':'abcde'},{'key':'ret'},{'text':'xy'},
                        {'key':'ret'},{'text':'12345'},{'key':'home'},
                        {'key':'right'},{'key':'right'},{'key':'down'},
                        {'key':'down'},{'key':'up'},{'key':'up'},{'key':'down'}],
              'final_rows':['TempleOS i386','DolDoc editor','C:/NativeVertical.DD','',
                            'abcde','xy'+bytes([0xDB]).decode('cp437'),'12345'],
            }),
            ("I64 vert_size;U8 *vert_text=DocSave(vert_doc,&vert_size);vert_size==15&&vert_text[5]==10&&vert_text[8]==5&&vert_text[9]==10;",['1']),
            ('Free(vert_text);DocWrite(vert_doc);',['1']),
            ('CDoc *boundary_doc=DocNew("C:/NativeBoundary.DD",Fs);',[]),
            ('DocEd(boundary_doc);',['1'],{
              'begin':'DOC EDIT begin\n','end':'DOC EDIT end\n',
              'initial_rows':['TempleOS i386','DolDoc editor','C:/NativeBoundary.DD','',
                              bytes([0xDB]).decode('cp437')],
              'events':[{'text':'a'},{'key':'ret'},{'key':'ret'},{'text':'b'},
                        {'key':'home'},{'key':'down'},{'text':'X'},
                        {'key':'backspace'},{'key':'delete'},{'key':'backspace'},
                        {'key':'home'},{'key':'backspace'},{'key':'end'},
                        {'key':'delete'}],
              'final_rows':['TempleOS i386','DolDoc editor','C:/NativeBoundary.DD','',
                            'ab'+bytes([0xDB]).decode('cp437')],
            }),
            ("I64 boundary_size;U8 *boundary_text=DocSave(boundary_doc,&boundary_size);boundary_size==3&&boundary_text[0]=='a'&&boundary_text[1]=='b'&&boundary_text[2]==5;",['1']),
            ('Free(boundary_text);DocWrite(boundary_doc);',['1']),
            ('CDoc *error_doc=DocNew("C:/NativeError.HC",Fs);U8 *error_source="6*;";',[]),
            ('while(*error_source)DocPutKey(error_doc,*error_source++);',[]),
            ('DocEd(error_doc);',['1'],{
              'begin':'DOC EDIT begin\n','end':'DOC EDIT end\n',
              'initial_rows':['TempleOS i386','DolDoc editor','C:/NativeError.HC','',
                              '6*;'+bytes([0xDB]).decode('cp437')],
              'events':[{'key':'f5'},
                        {'expect_rows':['TempleOS i386','Document execution',
                                        'C:/NativeError.HC','',
                                        'Error: Missing expression at ','',
                                        'Press Esc to return to editor'],
                         'label':'syntax-error'},
                        {'key':'esc'},{'key':'end'},{'key':'backspace'},{'key':'backspace'},
                        {'text':'*7;'},{'key':'f5'},
                        {'expect_rows':['TempleOS i386','Document execution',
                                        'C:/NativeError.HC','','42','',
                                        'Press Esc to return to editor'],
                         'label':'corrected-result'},
                        {'key':'esc'}],
              'final_rows':['TempleOS i386','DolDoc editor','C:/NativeError.HC','',
                            '6*7;'+bytes([0xDB]).decode('cp437')],
            }),
            ('DocDel(error_doc);',[]),
            ('CDoc *line_error_doc=DocNew("C:/NativeLineError.HC",Fs);',[]),
            ("DocPutKey(line_error_doc,'1');DocPutKey(line_error_doc,';');DocPutKey(line_error_doc,10);",[]),
            ("DocPutKey(line_error_doc,'6');DocPutKey(line_error_doc,'*');DocPutKey(line_error_doc,';');DocPutKey(line_error_doc,10);",[]),
            ("DocPutKey(line_error_doc,'3');DocPutKey(line_error_doc,';');",[]),
            ('DocEd(line_error_doc);',['1'],{
              'begin':'DOC EDIT begin\n','end':'DOC EDIT end\n',
              'initial_rows':['TempleOS i386','DolDoc editor','C:/NativeLineError.HC','',
                              '1;','6*;','3;'+bytes([0xDB]).decode('cp437')],
              'events':[{'key':'f5'},
                        {'expect_rows':['TempleOS i386','Document execution',
                                        'C:/NativeLineError.HC','','1',
                                        'Error: Missing expression at ','',
                                        'Press Esc to return to editor'],
                         'label':'multiline-syntax-error'},
                        {'key':'esc'},
                        {'wait_log':'DOC EXEC diagnostic line 0000000000000002\n'},
                        {'expect_rows':['TempleOS i386','DolDoc editor',
                                        'C:/NativeLineError.HC','','1;',
                                        bytes([0xDB]).decode('cp437')+'6*;','3;'],
                         'label':'diagnostic-line-selected'},
                        {'key':'delete'},{'key':'delete'},{'key':'delete'},
                        {'text':'6*7;'},{'key':'f5'},
                        {'expect_rows':['TempleOS i386','Document execution',
                                        'C:/NativeLineError.HC','','1','42','3','',
                                        'Press Esc to return to editor'],
                         'label':'diagnostic-corrected'},
                        {'key':'esc'}],
              'final_rows':['TempleOS i386','DolDoc editor','C:/NativeLineError.HC','',
                            '1;','6*7;'+bytes([0xDB]).decode('cp437'),'3;'],
            }),
            ('DocDel(line_error_doc);',[]),
            ('CDoc *except_doc=DocNew("C:/NativeExcept.HC",Fs);U8 *except_source="throw(1);";',[]),
            ('while(*except_source)DocPutKey(except_doc,*except_source++);',[]),
            ('DocEd(except_doc);',['1'],{
              'begin':'DOC EDIT begin\n','end':'DOC EDIT end\n',
              'initial_rows':['TempleOS i386','DolDoc editor','C:/NativeExcept.HC','',
                              'throw(1);'+bytes([0xDB]).decode('cp437')],
              'events':[{'key':'f5'},
                        {'expect_rows':['TempleOS i386','Document execution',
                                        'C:/NativeExcept.HC','','Exception','',
                                        'Press Esc to return to editor'],
                         'label':'runtime-exception'},
                        {'key':'esc'}]+[{'key':'backspace'}]*9+
                       [{'text':'6*7;'},{'key':'f5'},
                        {'expect_rows':['TempleOS i386','Document execution',
                                        'C:/NativeExcept.HC','','42','',
                                        'Press Esc to return to editor'],
                         'label':'runtime-recovery'},
                        {'key':'esc'}],
              'final_rows':['TempleOS i386','DolDoc editor','C:/NativeExcept.HC','',
                            '6*7;'+bytes([0xDB]).decode('cp437')],
            }),
            ('DocDel(except_doc);',[]),
            ('CDoc *float_doc=DocNew("C:/NativeFloat.HC",Fs);U8 *float_source="1.5+2.25;";',[]),
            ('while(*float_source)DocPutKey(float_doc,*float_source++);',[]),
            ('DocEd(float_doc);',['1'],{
              'begin':'DOC EDIT begin\n','end':'DOC EDIT end\n',
              'initial_rows':['TempleOS i386','DolDoc editor','C:/NativeFloat.HC','',
                              '1.5+2.25;'+bytes([0xDB]).decode('cp437')],
              'events':[{'key':'f5'},
                        {'expect_rows':['TempleOS i386','Document execution',
                                        'C:/NativeFloat.HC','','3.75','',
                                        'Press Esc to return to editor'],
                         'label':'software-f64'},
                        {'key':'esc'}],
              'final_rows':['TempleOS i386','DolDoc editor','C:/NativeFloat.HC','',
                            '1.5+2.25;'+bytes([0xDB]).decode('cp437')],
            }),
            ('DocDel(float_doc);',[]),
            ('CDoc *unsaved_doc=DocNew("C:/Missing/Unsaved.HC",Fs);U8 *unsaved_source="6*7;";',[]),
            ('while(*unsaved_source)DocPutKey(unsaved_doc,*unsaved_source++);',[]),
            ('DocEd(unsaved_doc);',['1'],{
              'begin':'DOC EDIT begin\n','end':'DOC EDIT end\n',
              'initial_rows':['TempleOS i386','DolDoc editor','C:/Missing/Unsaved.HC','',
                              '6*7;'+bytes([0xDB]).decode('cp437')],
              'events':[{'key':'f5'},
                        {'expect_rows':['TempleOS i386','Document execution',
                                        'C:/Missing/Unsaved.HC','','Save failed','42','',
                                        'Press Esc to return to editor'],
                         'label':'save-failure'},
                        {'key':'esc'}],
              'final_rows':['TempleOS i386','DolDoc editor','C:/Missing/Unsaved.HC','',
                            '6*7;'+bytes([0xDB]).decode('cp437')],
            }),
            ("I64 unsaved_size;U8 *unsaved_text=DocSave(unsaved_doc,&unsaved_size);unsaved_size==5&&unsaved_text[0]=='6'&&unsaved_text[1]=='*'&&unsaved_text[2]=='7'&&unsaved_text[3]==';'&&unsaved_text[4]==5;",['1']),
            ('Free(unsaved_text);DocDel(unsaved_doc);',[]),
            ('DirMk("C:/Project");',['1']),
            ('DirMk("C:/Project/Sub");',['1']),
            ('DirMk("C:/Project/MoveMe");',['1']),
            ('FileRename("C:/Project/MoveMe","C:/Project/Moved");',['1']),
            ('CDoc *temp_doc=DocNew("C:/Project/Sub/Temp.HC",Fs);DocPutKey(temp_doc,\'4\');DocPutKey(temp_doc,\'2\');DocWrite(temp_doc);DocDel(temp_doc);',['1']),
            ('FileRename("C:/Project/Sub/Temp.HC","C:/Project/Sub/Renamed.HC");',['1']),
            ('CDoc *renamed_doc=DocRead("C:/Project/Sub/Renamed.HC");I64 renamed_size;U8 *renamed_text=DocSave(renamed_doc,&renamed_size);',[]),
            ('renamed_size==3&&renamed_text[0]==\'4\'&&renamed_text[1]==\'2\'&&renamed_text[2]==5;',['1']),
            ('Free(renamed_text);DocDel(renamed_doc);FileMove("C:/Project/Sub/Renamed.HC","C:/Project/Moved/Transferred.HC");',['1']),
            ('CDoc *transferred_doc=DocRead("C:/Project/Moved/Transferred.HC");I64 transferred_size;U8 *transferred_text=DocSave(transferred_doc,&transferred_size);',[]),
            ('!DocRead("C:/Project/Sub/Renamed.HC")&&transferred_size==3&&transferred_text[0]==\'4\'&&transferred_text[1]==\'2\'&&transferred_text[2]==5;',['1']),
            ('Free(transferred_text);DocDel(transferred_doc);FileDel("C:/Project/Moved/Transferred.HC");',['1']),
            ('!DocRead("C:/Project/Sub/Temp.HC")&&!DocRead("C:/Project/Moved/Transferred.HC");',['1']),
            ('CDoc *relative_doc=DocNew("Project/Sub/Relative.HC",Fs);U8 *relative_source="8*8;";',[]),
            ('while(*relative_source)DocPutKey(relative_doc,*relative_source++);',[]),
            ('DocEd(relative_doc);',['1'],{
              'begin':'DOC EDIT begin\n','end':'DOC EDIT end\n',
              'initial_rows':['TempleOS i386','DolDoc editor','Project/Sub/Relative.HC','',
                              '8*8;'+bytes([0xDB]).decode('cp437')],
              'events':[{'key':'f5'},
                        {'expect_rows':['TempleOS i386','Document execution',
                                        'Project/Sub/Relative.HC','','64','',
                                        'Press Esc to return to editor'],
                         'label':'relative-result'},
                        {'key':'esc'}],
              'final_rows':['TempleOS i386','DolDoc editor','Project/Sub/Relative.HC','',
                            '8*8;'+bytes([0xDB]).decode('cp437')],
            }),
            ('DocDel(relative_doc);',[]),
            ('CDoc *nested_doc=DocNew("C:/Project/Sub/Main.HC",Fs);U8 *nested_source="7*7;";',[]),
            ('while(*nested_source)DocPutKey(nested_doc,*nested_source++);',[]),
            ('DocEd(nested_doc);',['1'],{
              'begin':'DOC EDIT begin\n','end':'DOC EDIT end\n',
              'initial_rows':['TempleOS i386','DolDoc editor','C:/Project/Sub/Main.HC','',
                              '7*7;'+bytes([0xDB]).decode('cp437')],
              'events':[{'key':'f5'},
                        {'expect_rows':['TempleOS i386','Document execution',
                                        'C:/Project/Sub/Main.HC','','49','',
                                        'Press Esc to return to editor'],
                         'label':'nested-result'},
                        {'key':'esc'}],
              'final_rows':['TempleOS i386','DolDoc editor','C:/Project/Sub/Main.HC','',
                            '7*7;'+bytes([0xDB]).decode('cp437')],
            }),
            ('DocDel(nested_doc);',[]),
            ('CDoc *break_doc=DocNew("C:/NativeBreak.HC",Fs);U8 *break_source="OutU8(0xE9,64);while(1){}";',[]),
            ('while(*break_source)DocPutKey(break_doc,*break_source++);',[]),
            ('DocEd(break_doc);',['1'],{
              'begin':'DOC EDIT begin\n','end':'DOC EDIT end\n',
              'initial_rows':['TempleOS i386','DolDoc editor','C:/NativeBreak.HC','',
                              'OutU8(0xE9,64);while(1){}'+bytes([0xDB]).decode('cp437')],
              'events':[{'mark_log':'@'},{'key':'f5'},
                        {'wait_log_after':'@'},
                        {'hotkey':'break','measure_latency':'interrupt_to_recovery_vga'},
                        {'expect_rows':['TempleOS i386','Document execution',
                                        'C:/NativeBreak.HC','','Exception','',
                                        'Press Esc to return to editor'],
                         'label':'keyboard-interrupt'},
                        {'key':'esc'}],
              'latency_budget_seconds':1.0,
              'final_rows':['TempleOS i386','DolDoc editor','C:/NativeBreak.HC','',
                            'OutU8(0xE9,64);while(1){}'+bytes([0xDB]).decode('cp437')],
            }),
            ('DocDel(break_doc);6*7;',['42']),
            ('CDoc *color_doc=DocNew("C:/NativeColor.DD",Fs);CDocEntry *color_entry=CAlloc(sizeof(CDocEntry));',[]),
            ('color_entry->type=DOCT_FOREGROUND;color_entry->attr=4;DocInsEntry(color_doc,color_entry);',['15','4']),
            ('U8 *red_text="red";while(*red_text)DocPutKey(color_doc,*red_text++);',[]),
            ('CDocEntry *default_entry=CAlloc(sizeof(CDocEntry));default_entry->type=DOCT_FOREGROUND;default_entry->attr=DOC_DFT;DocInsEntry(color_doc,default_entry);',['15','-2147483648']),
            ('U8 *plain_text=" plain";while(*plain_text)DocPutKey(color_doc,*plain_text++);',[]),
            ('CDocEntry *background_entry=CAlloc(sizeof(CDocEntry));background_entry->type=DOCT_BACKGROUND;background_entry->attr=1;DocInsEntry(color_doc,background_entry);',['16','1']),
            ('U8 *blue_text=" blue";while(*blue_text)DocPutKey(color_doc,*blue_text++);',[]),
            ('CDocEntry *background_default=CAlloc(sizeof(CDocEntry));background_default->type=DOCT_BACKGROUND;background_default->attr=DOC_DFT;DocInsEntry(color_doc,background_default);',['16','-2147483648']),
            ('U8 *end_text=" end";while(*end_text)DocPutKey(color_doc,*end_text++);',[]),
            ('CDocEntry *invert_entry=CAlloc(sizeof(CDocEntry));invert_entry->type=DOCT_INVERT;invert_entry->attr=1;DocInsEntry(color_doc,invert_entry);',['22','1']),
            ('U8 *invert_text=" inv";while(*invert_text)DocPutKey(color_doc,*invert_text++);',[]),
            ('CDocEntry *normal_entry=CAlloc(sizeof(CDocEntry));normal_entry->type=DOCT_INVERT;normal_entry->attr=0;DocInsEntry(color_doc,normal_entry);',['22','0']),
            ('CDocEntry *underline_entry=CAlloc(sizeof(CDocEntry));underline_entry->type=DOCT_UNDERLINE;underline_entry->attr=1;DocInsEntry(color_doc,underline_entry);',['23','1']),
            ('U8 *underline_text=" under";while(*underline_text)DocPutKey(color_doc,*underline_text++);',[]),
            ('CDocEntry *plain_entry=CAlloc(sizeof(CDocEntry));plain_entry->type=DOCT_UNDERLINE;plain_entry->attr=0;DocInsEntry(color_doc,plain_entry);',['23','0']),
            ('U8 *done_text=" done";while(*done_text)DocPutKey(color_doc,*done_text++);',[]),
            ('DocEd(color_doc);',['1'],{
              'begin':'DOC EDIT begin\n','end':'DOC EDIT end\n',
              'initial_rows':['TempleOS i386','DolDoc editor','C:/NativeColor.DD','',
                              'red plain blue end inv under done'+bytes([0xDB]).decode('cp437')],
              'initial_colors':({(4,index):4 for index in range(3)}|
                                {(4,index):15 for index in range(18,22)}),
              'initial_backgrounds':({(4,index):1 for index in range(9,14)}|
                                     {(4,index):0 for index in range(18,22)}),
              'initial_underlines':{(4,index) for index in range(22,28)},
              'events':[],
              'final_rows':['TempleOS i386','DolDoc editor','C:/NativeColor.DD','',
                            'red plain blue end inv under done'+bytes([0xDB]).decode('cp437')],
              'final_colors':({(4,index):4 for index in range(3)}|
                              {(4,index):15 for index in range(18,22)}),
              'final_backgrounds':({(4,index):1 for index in range(9,14)}|
                                   {(4,index):0 for index in range(18,22)}),
              'final_underlines':{(4,index) for index in range(22,28)},
            }),
            ('DocWrite(color_doc);',['1']),
            ('DocDel(color_doc);',[]),
            ('CDoc *style_keys=DocNew("C:/NativeStyleKeys.DD",Fs);',[]),
            ('DocEd(style_keys);',['1'],{
              'begin':'DOC EDIT begin\n','end':'DOC EDIT end\n',
              'initial_rows':['TempleOS i386','DolDoc editor','C:/NativeStyleKeys.DD','',
                              bytes([0xDB]).decode('cp437')],
              'events':[{'ctrl_key':'u'},{'text':'under'},
                        {'ctrl_key':'u','shift':True},{'text':' '},
                        {'ctrl_key':'z'},{'text':'inv'},
                        {'ctrl_key':'z','shift':True},{'text':' done'}],
              'final_rows':['TempleOS i386','DolDoc editor','C:/NativeStyleKeys.DD','',
                            'under inv done'+bytes([0xDB]).decode('cp437')],
              'final_colors':{(4,index):15 for index in range(6,9)},
              'final_backgrounds':{(4,index):0 for index in range(6,9)},
              'final_underlines':{(4,index) for index in range(5)},
            }),
            ('DocWrite(style_keys);',['1']),
            ('DocDel(style_keys);',[]),
            ('CDoc *blink_doc=DocNew("C:/NativeBlink.DD",Fs);',[]),
            ('DocEd(blink_doc);',['1'],{
              'begin':'DOC EDIT begin\n','end':'DOC EDIT end\n',
              'initial_rows':['TempleOS i386','DolDoc editor','C:/NativeBlink.DD','',
                              bytes([0xDB]).decode('cp437')],
              'events':[{'ctrl_key':'k'},{'text':'blink'},
                        {'ctrl_key':'k','shift':True},{'text':' steady'},
                        {'expect_rows':['TempleOS i386','DolDoc editor','C:/NativeBlink.DD','',
                                        'blink steady'+bytes([0xDB]).decode('cp437')],
                         'colors':{(4,index):15 for index in range(5)},
                         'backgrounds':{(4,index):0 for index in range(5)},
                         'label':'blink-on'},
                        {'expect_rows':['TempleOS i386','DolDoc editor','C:/NativeBlink.DD','',
                                        'blink steady'+bytes([0xDB]).decode('cp437')],
                         'label':'blink-off'},
                        {'ctrl_key':'s'},
                        {'expect_rows':['TempleOS i386','DolDoc editor - Saved',
                                        'C:/NativeBlink.DD','',
                                        'blink steady'+bytes([0xDB]).decode('cp437')],
                         'label':'ctrl-save'}],
              'final_rows':['TempleOS i386','DolDoc editor - Saved','C:/NativeBlink.DD','',
                            'blink steady'+bytes([0xDB]).decode('cp437')],
            }),
            ('I64 blink_size;U8 *blink_text=DocSave(blink_doc,&blink_size);blink_size==25&&blink_text[0]==36&&blink_text[1]==66&&blink_text[2]==75&&blink_text[24]==5;',['1']),
            ('Free(blink_text);',[]),
            ('DocDel(blink_doc);',[]),
            ('Ed("C:/StandaloneEdit.DD");',['1'],{
              'begin':'DOC EDIT begin\n','end':'DOC EDIT end\n',
              'initial_rows':['TempleOS i386','DolDoc editor','C:/StandaloneEdit.DD','',
                              bytes([0xDB]).decode('cp437')],
              'events':[{'text':'standalone'}],
              'final_rows':['TempleOS i386','DolDoc editor','C:/StandaloneEdit.DD','',
                            'standalone'+bytes([0xDB]).decode('cp437')],
            }),
            ('CDoc *program_doc=DocNew("C:/NativeProgram.HC",Fs);U8 *program_decl="I64 PersistentDocAnswer()";',[]),
            ('while(*program_decl)DocPutKey(program_doc,*program_decl++);DocPutKey(program_doc,10);',[]),
            ('U8 *program_body="{return 6*7;}";while(*program_body)DocPutKey(program_doc,*program_body++);DocPutKey(program_doc,10);',[]),
            ('U8 *program_call="PersistentDocAnswer;";while(*program_call)DocPutKey(program_doc,*program_call++);',[]),
            ('DocEd(program_doc);',['1'],{
              'begin':'DOC EDIT begin\n','end':'DOC EDIT end\n',
              'initial_rows':['TempleOS i386','DolDoc editor','C:/NativeProgram.HC','',
                              'I64 PersistentDocAnswer()','{return 6*7;}',
                              'PersistentDocAnswer;'+bytes([0xDB]).decode('cp437')],
              'events':[{'key':'f5'},
                        {'expect_rows':['TempleOS i386','Document execution',
                                        'C:/NativeProgram.HC','','42','',
                                        'Press Esc to return to editor'],
                         'label':'execution-result'},
                        {'key':'esc'}],
              'final_rows':['TempleOS i386','DolDoc editor','C:/NativeProgram.HC','',
                            'I64 PersistentDocAnswer()','{return 6*7;}',
                            'PersistentDocAnswer;'+bytes([0xDB]).decode('cp437')],
            }),
            ('PersistentDocAnswer==42;',['1']),
          ],
          'command_timeout':60,
        }
        result['create_edit_save']=INPUT(candidate,args.out/'create-edit-save',startup_check=create,snapshot=False)
        reopen={
          'status':'ok','answers':[],
          'commands':[
            ('Dir("C:/Project/MoveMe");',['-1']),
            ('Dir("C:/Project/Moved");',['./','../','2']),
            ('!DirDel("C:/Project/Sub")&&DirDel("C:/Project/Moved");',['1']),
            ('!DocRead("C:/Project/Sub/Temp.HC")&&!DocRead("C:/Project/Sub/Renamed.HC")&&!DocRead("C:/Project/Moved/Transferred.HC");',['1']),
            ('CDoc *saved_doc=DocRead("C:/NativeEdit.DD");',[]),
            ('saved_doc!=0;',['1']),
            ('DocEd(saved_doc);',['1'],{
              'begin':'DOC EDIT begin\n','end':'DOC EDIT end\n',
              'initial_rows':['TempleOS i386','DolDoc editor','C:/NativeEdit.DD','',
                              'aZ'+bytes([0xDB]).decode('cp437')+'bc'],
              'events':[],
              'final_rows':['TempleOS i386','DolDoc editor','C:/NativeEdit.DD','',
                            'aZ'+bytes([0xDB]).decode('cp437')+'bc'],
            }),
            ("I64 saved_size;U8 *saved_text=DocSave(saved_doc,&saved_size);saved_text[0]=='a'&&saved_text[1]=='Z'&&saved_text[2]==5&&saved_text[3]=='b'&&saved_text[4]=='c'&&saved_text[5]==0;",['1']),
            ('saved_size==5;',['1']),
            ('Free(saved_text);DocDel(saved_doc);',[]),
            ('CDoc *saved_color=DocRead("C:/NativeColor.DD");',[]),
            ('saved_color!=0;',['1']),
            ('DocEd(saved_color);',['1'],{
              'begin':'DOC EDIT begin\n','end':'DOC EDIT end\n',
              'initial_rows':['TempleOS i386','DolDoc editor','C:/NativeColor.DD','',
                              'red plain blue end inv under done'+bytes([0xDB]).decode('cp437')],
              'initial_colors':({(4,index):4 for index in range(3)}|
                                {(4,index):15 for index in range(18,22)}),
              'initial_backgrounds':({(4,index):1 for index in range(9,14)}|
                                     {(4,index):0 for index in range(18,22)}),
              'initial_underlines':{(4,index) for index in range(22,28)},
              'events':[],
              'final_rows':['TempleOS i386','DolDoc editor','C:/NativeColor.DD','',
                            'red plain blue end inv under done'+bytes([0xDB]).decode('cp437')],
              'final_colors':({(4,index):4 for index in range(3)}|
                              {(4,index):15 for index in range(18,22)}),
              'final_backgrounds':({(4,index):1 for index in range(9,14)}|
                                   {(4,index):0 for index in range(18,22)}),
              'final_underlines':{(4,index) for index in range(22,28)},
            }),
            ('I64 saved_color_size;U8 *saved_color_text=DocSave(saved_color,&saved_color_size);',[]),
            ('saved_color_size==78&&saved_color_text[38]==36&&saved_color_text[39]==73&&saved_color_text[43]==36&&saved_color_text[48]==36&&saved_color_text[54]==36;',['1']),
            ('saved_color_text[55]==85&&saved_color_text[59]==36&&saved_color_text[66]==36&&saved_color_text[71]==36&&saved_color_text[77]==5;',['1']),
            ('Free(saved_color_text);DocDel(saved_color);',[]),
            ('CDoc *saved_style_keys=DocRead("C:/NativeStyleKeys.DD");',[]),
            ('saved_style_keys!=0;',['1']),
            ('DocEd(saved_style_keys);',['1'],{
              'begin':'DOC EDIT begin\n','end':'DOC EDIT end\n',
              'initial_rows':['TempleOS i386','DolDoc editor','C:/NativeStyleKeys.DD','',
                              'under inv done'+bytes([0xDB]).decode('cp437')],
              'initial_colors':{(4,index):15 for index in range(6,9)},
              'initial_backgrounds':{(4,index):0 for index in range(6,9)},
              'initial_underlines':{(4,index) for index in range(5)},
              'events':[],
              'final_rows':['TempleOS i386','DolDoc editor','C:/NativeStyleKeys.DD','',
                            'under inv done'+bytes([0xDB]).decode('cp437')],
              'final_colors':{(4,index):15 for index in range(6,9)},
              'final_backgrounds':{(4,index):0 for index in range(6,9)},
              'final_underlines':{(4,index) for index in range(5)},
            }),
            ('I64 saved_style_size;U8 *saved_style_text=DocSave(saved_style_keys,&saved_style_size);saved_style_size==39&&saved_style_text[0]==36&&saved_style_text[38]==5;',['1']),
            ('Free(saved_style_text);DocDel(saved_style_keys);',[]),
            ('CDoc *saved_blink=DocRead("C:/NativeBlink.DD");',[]),
            ('saved_blink!=0;',['1']),
            ('DocEd(saved_blink);',['1'],{
              'begin':'DOC EDIT begin\n','end':'DOC EDIT end\n',
              'initial_rows':['TempleOS i386','DolDoc editor','C:/NativeBlink.DD','',
                              'blink steady'+bytes([0xDB]).decode('cp437')],
              'events':[{'expect_rows':['TempleOS i386','DolDoc editor','C:/NativeBlink.DD','',
                                        'blink steady'+bytes([0xDB]).decode('cp437')],
                         'colors':{(4,index):15 for index in range(5)},
                         'backgrounds':{(4,index):0 for index in range(5)},
                         'label':'persisted-blink-on'},
                        {'expect_rows':['TempleOS i386','DolDoc editor','C:/NativeBlink.DD','',
                                        'blink steady'+bytes([0xDB]).decode('cp437')],
                         'label':'persisted-blink-off'}],
              'final_rows':['TempleOS i386','DolDoc editor','C:/NativeBlink.DD','',
                            'blink steady'+bytes([0xDB]).decode('cp437')],
            }),
            ('I64 saved_blink_size;U8 *saved_blink_text=DocSave(saved_blink,&saved_blink_size);saved_blink_size==25&&saved_blink_text[1]==66&&saved_blink_text[2]==75;',['1']),
            ('Free(saved_blink_text);DocDel(saved_blink);',[]),
            ('Ed("C:/StandaloneEdit.DD");',['0'],{
              'begin':'DOC EDIT begin\n','end':'DOC EDIT end\n','exit_shift':True,
              'initial_rows':['TempleOS i386','DolDoc editor','C:/StandaloneEdit.DD','',
                              'standalone'+bytes([0xDB]).decode('cp437')],
              'events':[{'text':'X'}],
              'final_rows':['TempleOS i386','DolDoc editor','C:/StandaloneEdit.DD','',
                            'standaloneX'+bytes([0xDB]).decode('cp437')],
            }),
            ('CDoc *standalone_read=DocRead("C:/StandaloneEdit.DD");I64 standalone_size;U8 *standalone_text=DocSave(standalone_read,&standalone_size);',[]),
            ('standalone_size==11&&standalone_text[0]==115&&standalone_text[9]==101&&standalone_text[10]==5;',['1']),
            ('Free(standalone_text);DocDel(standalone_read);',[]),
            ('CDoc *saved_multi=DocRead("C:/NativeMulti.DD");',[]),
            ('saved_multi!=0;',['1']),
            ('DocEd(saved_multi);',['1'],{
              'begin':'DOC EDIT begin\n','end':'DOC EDIT end\n',
              'initial_rows':['TempleOS i386','DolDoc editor','C:/NativeMulti.DD','',
                              'abZ'+bytes([0xDB]).decode('cp437')+'cd'],
              'events':[],
              'final_rows':['TempleOS i386','DolDoc editor','C:/NativeMulti.DD','',
                            'abZ'+bytes([0xDB]).decode('cp437')+'cd'],
            }),
            ("I64 saved_multi_size;U8 *saved_multi_text=DocSave(saved_multi,&saved_multi_size);saved_multi_size==6&&saved_multi_text[0]=='a'&&saved_multi_text[1]=='b'&&saved_multi_text[2]=='Z'&&saved_multi_text[3]==5&&saved_multi_text[4]=='c'&&saved_multi_text[5]=='d';",['1']),
            ('Free(saved_multi_text);DocDel(saved_multi);',[]),
            ('CDoc *saved_nav=DocRead("C:/NativeNavigation.DD");',[]),
            ('saved_nav!=0;',['1']),
            ('DocEd(saved_nav);',['1'],{
              'begin':'DOC EDIT begin\n','end':'DOC EDIT end\n',
              'initial_rows':['TempleOS i386','DolDoc editor','C:/NativeNavigation.DD','',
                              'a       '+bytes([0xDB]).decode('cp437')+'c'],
              'events':[],
              'final_rows':['TempleOS i386','DolDoc editor','C:/NativeNavigation.DD','',
                            'a       '+bytes([0xDB]).decode('cp437')+'c'],
            }),
            ("I64 saved_nav_size;U8 *saved_nav_text=DocSave(saved_nav,&saved_nav_size);saved_nav_size==4&&saved_nav_text[0]=='a'&&saved_nav_text[1]==9&&saved_nav_text[2]==5&&saved_nav_text[3]=='c';",['1']),
            ('Free(saved_nav_text);DocDel(saved_nav);',[]),
            ('CDoc *saved_vert=DocRead("C:/NativeVertical.DD");',[]),
            ('saved_vert!=0;',['1']),
            ('DocEd(saved_vert);',['1'],{
              'begin':'DOC EDIT begin\n','end':'DOC EDIT end\n',
              'initial_rows':['TempleOS i386','DolDoc editor','C:/NativeVertical.DD','',
                              'abcde','xy'+bytes([0xDB]).decode('cp437'),'12345'],
              'events':[],
              'final_rows':['TempleOS i386','DolDoc editor','C:/NativeVertical.DD','',
                            'abcde','xy'+bytes([0xDB]).decode('cp437'),'12345'],
            }),
            ("I64 saved_vert_size;U8 *saved_vert_text=DocSave(saved_vert,&saved_vert_size);saved_vert_size==15&&saved_vert_text[5]==10&&saved_vert_text[8]==5&&saved_vert_text[9]==10;",['1']),
            ('Free(saved_vert_text);DocDel(saved_vert);',[]),
            ('CDoc *saved_boundary=DocRead("C:/NativeBoundary.DD");',[]),
            ('saved_boundary!=0;',['1']),
            ('DocEd(saved_boundary);',['1'],{
              'begin':'DOC EDIT begin\n','end':'DOC EDIT end\n',
              'initial_rows':['TempleOS i386','DolDoc editor','C:/NativeBoundary.DD','',
                              'ab'+bytes([0xDB]).decode('cp437')],
              'events':[],
              'final_rows':['TempleOS i386','DolDoc editor','C:/NativeBoundary.DD','',
                            'ab'+bytes([0xDB]).decode('cp437')],
            }),
            ("I64 saved_boundary_size;U8 *saved_boundary_text=DocSave(saved_boundary,&saved_boundary_size);saved_boundary_size==3&&saved_boundary_text[0]=='a'&&saved_boundary_text[1]=='b'&&saved_boundary_text[2]==5;",['1']),
            ('Free(saved_boundary_text);DocDel(saved_boundary);',[]),
            ('CDoc *saved_program=DocRead("C:/NativeProgram.HC");',[]),
            ('saved_program!=0;',['1']),
            ('DocEd(saved_program);',['1'],{
              'begin':'DOC EDIT begin\n','end':'DOC EDIT end\n',
              'initial_rows':['TempleOS i386','DolDoc editor','C:/NativeProgram.HC','',
                              'I64 PersistentDocAnswer()','{return 6*7;}',
                              'PersistentDocAnswer;'+bytes([0xDB]).decode('cp437')],
              'events':([{'key':'left'},{'delay':0.1}]*23)+
                       [{'key':'backspace'},{'text':'8'},{'key':'f5'},
                        {'expect_rows':['TempleOS i386','Document execution',
                                        'C:/NativeProgram.HC','','48','',
                                        'Press Esc to return to editor'],
                         'label':'revised-execution-result'},
                        {'key':'esc'}],
              'final_rows':['TempleOS i386','DolDoc editor','C:/NativeProgram.HC','',
                            'I64 PersistentDocAnswer()',
                            '{return 6*8'+bytes([0xDB]).decode('cp437')+';}',
                            'PersistentDocAnswer;'],
            }),
            ('PersistentDocAnswer==48;',['1']),
            ('DocDel(saved_program);',[]),
          ],
          'command_timeout':60,
        }
        result['reopen_after_boot']=INPUT(candidate,args.out/'reopen',startup_check=reopen,snapshot=False)
        revised={
          'status':'ok','answers':[],
          'commands':[
            ('Dir("C:/Project/MoveMe");',['-1']),
            ('Dir("C:/Project/Moved");',['-1']),
            ('CDoc *revised_program=DocRead("C:/NativeProgram.HC");',[]),
            ('revised_program!=0;',['1']),
            ('DocEd(revised_program);',['1'],{
              'begin':'DOC EDIT begin\n','end':'DOC EDIT end\n',
              'initial_rows':['TempleOS i386','DolDoc editor','C:/NativeProgram.HC','',
                              'I64 PersistentDocAnswer()',
                              '{return 6*8'+bytes([0xDB]).decode('cp437')+';}',
                              'PersistentDocAnswer;'],
              'events':[{'key':'f5'},
                        {'expect_rows':['TempleOS i386','Document execution',
                                        'C:/NativeProgram.HC','','48','',
                                        'Press Esc to return to editor'],
                         'label':'persisted-revision-result'},
                        {'key':'esc'}],
              'final_rows':['TempleOS i386','DolDoc editor','C:/NativeProgram.HC','',
                            'I64 PersistentDocAnswer()',
                            '{return 6*8'+bytes([0xDB]).decode('cp437')+';}',
                            'PersistentDocAnswer;'],
            }),
            ('PersistentDocAnswer==48;',['1']),
            ('DocDel(revised_program);',[]),
            ('CDoc *revised_nested=DocRead("C:/Project/Sub/Main.HC");',[]),
            ('revised_nested!=0;',['1']),
            ('DocEd(revised_nested);',['1'],{
              'begin':'DOC EDIT begin\n','end':'DOC EDIT end\n',
              'initial_rows':['TempleOS i386','DolDoc editor','C:/Project/Sub/Main.HC','',
                              '7*7;'+bytes([0xDB]).decode('cp437')],
              'events':[{'key':'f5'},
                        {'expect_rows':['TempleOS i386','Document execution',
                                        'C:/Project/Sub/Main.HC','','49','',
                                        'Press Esc to return to editor'],
                         'label':'persisted-nested-result'},
                        {'key':'esc'}],
              'final_rows':['TempleOS i386','DolDoc editor','C:/Project/Sub/Main.HC','',
                            '7*7;'+bytes([0xDB]).decode('cp437')],
            }),
            ('DocDel(revised_nested);',[]),
            ('CDoc *revised_relative=DocRead("Project/Sub/Relative.HC");',[]),
            ('revised_relative!=0;',['1']),
            ('DocEd(revised_relative);',['1'],{
              'begin':'DOC EDIT begin\n','end':'DOC EDIT end\n',
              'initial_rows':['TempleOS i386','DolDoc editor','Project/Sub/Relative.HC','',
                              '8*8;'+bytes([0xDB]).decode('cp437')],
              'events':[{'key':'f5'},
                        {'expect_rows':['TempleOS i386','Document execution',
                                        'Project/Sub/Relative.HC','','64','',
                                        'Press Esc to return to editor'],
                         'label':'persisted-relative-result'},
                        {'key':'esc'}],
              'final_rows':['TempleOS i386','DolDoc editor','Project/Sub/Relative.HC','',
                            '8*8;'+bytes([0xDB]).decode('cp437')],
            }),
            ('DocDel(revised_relative);',[]),
          ],
          'command_timeout':60,
        }
        result['revised_after_second_boot']=INPUT(candidate,args.out/'revised',startup_check=revised,snapshot=False)
        result['filesystem_integrity']=verify_redsea_project(candidate)
        result['result']='pass'
    except Exception as exc:
        result['failure']=f'{type(exc).__name__}: {exc}'
        for phase in ('create-edit-save','reopen','revised'):
            checkpoint=args.out/phase/'checkpoint.json'
            debug=args.out/phase/'debug.log'
            if checkpoint.exists():
                result['failure_phase']=phase
                result['failure_checkpoint']=json.loads(checkpoint.read_text())
                if debug.exists() and 'COMMAND ERROR\n' in debug.read_text():
                    result['failure_kind']='guest command rejected'
    finally:
        result['source_disk_unchanged']=hashlib.sha256(args.disk.read_bytes()).hexdigest()==source_hash
        if not result['source_disk_unchanged']:
            result['result']='fail'
            result['failure']='Source disk changed during acceptance'
        result['candidate_sha256']=hashlib.sha256(candidate.read_bytes()).hexdigest()
        (args.out/'result.json').write_text(json.dumps(result,indent=2)+'\n')
    print(json.dumps(result,indent=2))
    return 0 if result['result']=='pass' else 1


if __name__=='__main__': raise SystemExit(main())
