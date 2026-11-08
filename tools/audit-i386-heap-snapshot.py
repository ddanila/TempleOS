#!/usr/bin/env python3
"""Audit a stopped ABI-100 i386 bootstrap heap and segmented output snapshot."""
import argparse, hashlib, struct, collections, json
from pathlib import Path
parser=argparse.ArgumentParser(description=__doc__)
parser.add_argument('snapshot',type=Path)
parser.add_argument('--heap',required=True,type=lambda x:int(x,0))
parser.add_argument('--output-owner',required=True,type=lambda x:int(x,0))
parser.add_argument('--report',required=True,type=Path)
parser.add_argument('--task-heap',action='append',default=[],type=lambda x:int(x,0),
                    help='Also census this native non-debug CHeapCtrl address; repeatable')
args=parser.parse_args()
b=args.snapshot.read_bytes()
if len(b)!=0x800000:raise ValueError('Expected an exact 8 MiB physical snapshot')
def u(p):return struct.unpack_from('<I',b,p)[0]
def q(p):return struct.unpack_from('<Q',b,p)[0]
base,size,used,peak,allocs,magic=struct.unpack_from('<6I',b,args.heap)
assert magic==0x48323349 and base+size<=len(b) and size%8==0
blocks={};sizes=collections.Counter();free=[];p=base
while p<base+size:
 span,requested,tag,res=struct.unpack_from('<4I',b,p)
 assert span>=24 and span%8==0 and p+span<=base+size and tag in (0x46523349,0x55523349),(hex(p),span,hex(tag))
 assert tag!=0x55523349 or 0<=requested<=span-16
 blocks[p+16]=(span,requested,tag)
 if tag==0x55523349:sizes[requested]+=1
 else:free.append(span)
 p+=span
assert sum(v[0] for v in blocks.values() if v[2]==0x55523349)==used
assert sum(sizes.values())==allocs
owner=args.output_owner;cc=u(owner+49);start=owner+53;p=start;seen=set();kinds=collections.Counter();ks=collections.defaultdict(collections.Counter);owned=set()
while p not in seen:
 assert 0<=p<len(b)-20
 seen.add(p);n,last,control,allocation,kind=struct.unpack_from('<5I',b,p)
 assert u(n+4)==p
 if control==cc:
  assert allocation in blocks and blocks[allocation][2]==0x55523349,(hex(p),hex(allocation),kind)
  owned.add(allocation);kinds[kind]+=1;ks[kind][blocks[allocation][1]]+=1
 p=n
assert p==start
assert owner in owned and ks[8][85]==1
chunks=[];p=u(owner+73);chunk_seen=set();expected_start=0
while p:
 assert p not in chunk_seen and p in blocks and blocks[p][2]==0x55523349
 chunk_seen.add(p)
 assert q(p+4)==expected_start and 0<q(p+12)<=512 and blocks[p][1]==20+q(p+12)
 chunks.append(dict(address=p,start=q(p+4),bytes=q(p+12),span=blocks[p][0]))
 expected_start+=q(p+12);owned.add(p);p=u(p)
assert expected_start==q(owner+12) and q(owner+4)<=expected_start
assert not q(owner+20) or expected_start<=q(owner+20)
r=dict(heap=dict(base=base,size=size,used=used,allocations=allocs,free_span=sum(free),largest_free_span=max(free,default=0),free_blocks=len(free)),size_counts=sizes.most_common(35),control=cc,ownership_kinds=dict(kinds),ownership_sizes={k:v.most_common() for k,v in ks.items()},output=dict(count=q(owner+4),capacity=q(owner+12),planned=q(owner+20),chunks=chunks),largest_allocations=sorted([(a,*v[:2]) for a,v in blocks.items() if v[2]==0x55523349],key=lambda x:x[1],reverse=True)[:25])
# A task heap's cached spans belong to page blocks nested inside the bootstrap
# backing allocations. Reconcile those layers without counting them twice.
r['task_heaps']=[]
for hc in args.task_heap:
 assert 0<=hc<=len(b)-1088 and b[hc+4:hc+8]==b'HcSV' and q(hc+12)==0
 spans=[];seen=set()
 for head in [u(hc+52)]+[u(hc+64+4*i) for i in range(256)]:
  a=head
  while a:
   assert 0<=a<=len(b)-12 and a not in seen
   seen.add(a);n=q(a+4)
   assert n>=12 and n%8==0 and a+n<=len(b)
   spans.append((a,n));a=u(a)
 spans.sort();merged=[]
 for a,n in spans:
  assert not merged or merged[-1][0]+merged[-1][1]<=a
  if merged and merged[-1][0]+merged[-1][1]==a:merged[-1][1]+=n
  else:merged.append([a,n])
 pages=[];a=u(hc+40);seen=set();covered=set()
 while a!=hc+40:
  assert 0<=a<=len(b)-16 and a not in seen and b[a+8:a+12]==b'MBUs'
  seen.add(a);n=u(a+12)*512
  assert n>=512 and a%512==0 and a+n<=len(b)
  assert u(u(a)+4)==a and u(u(a+4))==a
  cached=0
  for x,size in spans:
   if a<=x<a+n:
    assert a+20<=x and x+size<=a+n-4 and x not in covered
    covered.add(x);cached+=size
  pages.append(dict(address=a,bytes=n,cached=cached,
                    whole_free=[a+20,(n-20)&~7] in merged))
  a=u(a)
 assert len(covered)==len(spans)
 allocated=sum(page['bytes'] for page in pages);cached=sum(n for _,n in spans)
 assert allocated==q(hc+20) and allocated-q(hc+28)-cached==24*len(pages)
 r['task_heaps'].append(dict(control=hc,allocated=allocated,used=q(hc+28),cached=cached,
   whole_free_bytes=sum(page['bytes'] for page in pages if page['whole_free']),pages=pages))
r['snapshot_sha256']=hashlib.sha256(b).hexdigest()
r['heap_descriptor']=args.heap;r['output_owner']=owner
r['scope']='ABI 100 bootstrap heap/control/output census, with optional native task cache/page accounting; not individual live task allocations or runtime qualification'
args.report.write_text(json.dumps(r,indent=2)+'\n')
print(f"PASS: {allocs} live allocations; {sum(free)} free bytes; {len(chunks)} output chunks")
