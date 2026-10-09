//Allocation-free module loading shared by the cross host and native i386 kernel.
#include "/Kernel/I386/ModuleCheck.HC"
#include "/Kernel/I386/ModuleBind.HH"

Bool I386NameEqual(U8 *a,U8 *b)
{
  while (*a && *a==*b) { a++; b++; }
  return *a==*b;
}

Bool I386BuffersOverlap(U8 *a,I64 an,U8 *b,I64 bn)
{
  U64 av=(a+0)(U64),bv=(b+0)(U64);
  if (av<bv) return bv-av<an;
  return av-bv<bn;
}

I64 I386FindSymbol(U8 **modules,I64 count,U8 *name,I64 kind,I64 *matches)
{
  CI386ModuleHeader *h;
  CI386ModuleRecord *r;
  U32 j,name_length=0;
  I64 i,base=8,result=0;
  //Caller has validated the module records and bounded NUL-terminated names.
  //A length mismatch cannot match; still scan every export for duplicates.
  while(name[name_length]) name_length++;
  *matches=0;
  for (i=0;i<count;i++) {
    h=modules[i]; r=modules[i]+h->records_offset;
    for (j=0;j<h->record_count;j++,r++)
      if ((r->kind==I386_MODULE_EXPORT || r->kind==I386_MODULE_DATA_EXPORT) &&
          (!kind || kind==r->kind) && r->name_length==name_length &&
          I386NameEqual(modules[i]+r->name_offset,name)) {
        (*matches)++; result=base+r->offset;
      }
    base+=h->code_size;
  }
  return result;
}

//Scratch belongs to this load invocation, not to shared module/global state.
//Overflow marks only its hash bucket; other buckets remain fully indexed.
//The high head bit requests the original scan, preserving duplicate counts.
class CI386SymbolSlot {
  U8 *name;
  U32 target,kind,next;
};
class CI386SymbolIndex {
  U32 heads[256];
  CI386SymbolSlot slots[512];
  Bool complete;
};
U32 I386SymbolBucket(U8 *name)
{
  U32 hash=0;
  while(*name) hash=hash*31+*name++;
  return hash&255;
}
U0 I386SymbolIndexBuild(CI386SymbolIndex *index,U8 **modules,I64 count)
{//Only validated, bounded names and module offsets are read here.
#ifdef I386_LOADER_NATIVE_BUILD
  //The validated total image, record counts and target offsets fit U32.
  //Build without host arithmetic helpers or allocating scratch from the heap.
  U8 **next=modules;
  CI386SymbolSlot *slot;
  U32 left=count,remaining,base=8,used=0;
  #assert sizeof(CI386SymbolSlot)==16
  index->complete=FALSE;
  asm {
    MOV EBX,U32 &index[EBP]
    LEA EDI,U32 CI386SymbolIndex.heads[EBX]
    MOV ECX,256
    XOR EAX,EAX
@@01:
    MOV U32 [EDI],EAX
    ADD EDI,4
    SUB ECX,1
    JNZ I32 @@01
@@10:
    MOV EAX,U32 &next[EBP]
    MOV ESI,U32 [EAX]
    ADD EAX,4
    MOV U32 &next[EBP],EAX
    MOV EAX,U32 CI386ModuleHeader.record_count[ESI]
    MOV U32 &remaining[EBP],EAX
    MOV EDI,U32 CI386ModuleHeader.records_offset[ESI]
    ADD EDI,ESI
    TEST EAX,EAX
    JZ I32 @@70
@@20:
    MOV ECX,U32 CI386ModuleRecord.kind[EDI]
    CMP ECX,I386_MODULE_EXPORT
    JE I32 @@30
    CMP ECX,I386_MODULE_DATA_EXPORT
    JNE I32 @@60
@@30:
    MOV EAX,U32 &used[EBP]
    CMP EAX,512
    JE I32 @@80
    MOV EDX,EAX
    SHL EDX,4
    ADD EDX,EBX
    LEA EDX,U32 CI386SymbolIndex.slots[EDX]
    MOV U32 &slot[EBP],EDX
    MOV U32 CI386SymbolSlot.kind[EDX],ECX
    MOV EAX,U32 CI386ModuleRecord.offset[EDI]
    ADD EAX,U32 &base[EBP]
    MOV U32 CI386SymbolSlot.target[EDX],EAX
    MOV ECX,U32 CI386ModuleRecord.name_offset[EDI]
    ADD ECX,ESI
    MOV U32 CI386SymbolSlot.name[EDX],ECX
    XOR EAX,EAX
@@40:
    MOVZX EDX,U8 [ECX]
    TEST EDX,EDX
    JZ I32 @@50
    PUSH EDX
    MOV EDX,EAX
    SHL EAX,5
    SUB EAX,EDX
    POP EDX
    ADD EAX,EDX
    ADD ECX,1
    JMP I32 @@40
@@50:
    AND EAX,255
    SHL EAX,2
    ADD EAX,EBX
    LEA EAX,U32 CI386SymbolIndex.heads[EAX]
    MOV ECX,U32 [EAX]
    MOV EDX,U32 &slot[EBP]
    MOV U32 CI386SymbolSlot.next[EDX],ECX
    MOV ECX,U32 &used[EBP]
    ADD ECX,1
    MOV U32 &used[EBP],ECX
    MOV U32 [EAX],ECX
@@60:
    ADD EDI,16
    SUB U32 &remaining[EBP],1
    JNZ I32 @@20
@@70:
    MOV EAX,U32 CI386ModuleHeader.code_size[ESI]
    ADD U32 &base[EBP],EAX
    SUB U32 &left[EBP],1
    JNZ I32 @@10
    MOV U8 CI386SymbolIndex.complete[EBX],1
    JMP I32 @@90
@@80:
    MOV ECX,U32 CI386ModuleRecord.name_offset[EDI]
    ADD ECX,ESI
    XOR EAX,EAX
@@81:
    MOVZX EDX,U8 [ECX]
    TEST EDX,EDX
    JZ I32 @@82
    PUSH EDX
    MOV EDX,EAX
    SHL EAX,5
    SUB EAX,EDX
    POP EDX
    ADD EAX,EDX
    ADD ECX,1
    JMP I32 @@81
@@82:
    AND EAX,255
    SHL EAX,2
    ADD EAX,EBX
    MOV ECX,U32 CI386SymbolIndex.heads[EAX]
    MOV EDX,0x80000000
    OR ECX,EDX
    MOV U32 CI386SymbolIndex.heads[EAX],ECX
    JMP I32 @@60
@@90:
  }
#else
  CI386ModuleHeader *h;
  CI386ModuleRecord *r;
  CI386SymbolSlot *slot;
  U32 j,used=0,base=8,bucket;
  I64 i;
  index->complete=FALSE;
  for(j=0;j<256;j++) index->heads[j]=0;
  for(i=0;i<count;i++) {
    h=modules[i]; r=modules[i]+h->records_offset;
    for(j=0;j<h->record_count;j++,r++)
      if(r->kind==I386_MODULE_EXPORT || r->kind==I386_MODULE_DATA_EXPORT) {
        bucket=I386SymbolBucket(modules[i]+r->name_offset);
        if(used==512) {
          index->heads[bucket]|=0x80000000;
        } else {
          slot=&index->slots[used]; slot->name=modules[i]+r->name_offset;
          slot->target=base+r->offset; slot->kind=r->kind;
          slot->next=index->heads[bucket]; index->heads[bucket]=++used;
        }
      }
    base+=h->code_size;
  }
  index->complete=TRUE;
#endif
}

I64 I386IndexedSymbol(CI386SymbolIndex *index,U8 **modules,I64 count,
  U8 *name,I64 kind,I64 *matches)
{
  CI386SymbolSlot *slot;
  U32 cursor;
  I64 result=0;
  if(!index || !index->complete) return I386FindSymbol(modules,count,name,kind,matches);
  cursor=index->heads[I386SymbolBucket(name)];
  if(cursor&0x80000000) return I386FindSymbol(modules,count,name,kind,matches);
  *matches=0;
  while(cursor) {
    slot=&index->slots[cursor-1];
    if((!kind || kind==slot->kind) && I386NameEqual(slot->name,name)) {
      (*matches)++; result=slot->target;
    }
    cursor=slot->next;
  }
  return result;
}

I64 I386BoundSymbol(U8 **modules,I64 count,U8 *name,I64 kind,I64 *matches,
  CI386ModuleBinding *bindings,I64 binding_count,I64 load_address,CI386SymbolIndex *index=0)
{
  I64 i,result=I386IndexedSymbol(index,modules,count,name,kind,matches);
  for (i=0;i<binding_count;i++)
    if ((!kind || bindings[i].kind==kind) && I386NameEqual(bindings[i].name,name)) {
      (*matches)++; result=(bindings[i].address+0)(U64)-load_address;
    }
  return result;
}
public I64 I386LoadBoundAt(U8 **modules,I64 *sizes,I64 count,U8 *image,
  I64 capacity,U8 *entry_name,CI386ModuleBinding *bindings,I64 binding_count,I64 load_address)
{//Return loaded size, or zero on failure. NULL image/zero capacity queries size.
 //Validate all references before writing. Caller owns buffers and execution lifetime.
  CI386ModuleHeader *h;
  CI386ModuleRecord *r;
  I64 i,j,k,n,total=8,matches,target,entry,base,patch,name_size,address;
  Bool pointers=FALSE;
  CI386SymbolIndex index;
  if (!modules || !sizes || !entry_name || count<=0 || count>U32_MAX/8 ||
      capacity<0 || capacity>U32_MAX || load_address< -1 || load_address>U32_MAX || binding_count<0 ||
      binding_count>U32_MAX/sizeof(CI386ModuleBinding) || (binding_count && (!bindings || (bindings+0)(U64)>
        0x100000000-binding_count*sizeof(CI386ModuleBinding)))) return 0;
  for (i=0;i<binding_count;i++) {
    if (!bindings[i].name || !bindings[i].address ||
        (bindings[i].kind!=I386_MODULE_EXPORT && bindings[i].kind!=I386_MODULE_DATA_EXPORT)) return 0;
    for (n=0;n<=255;n++) if (!bindings[i].name[n]) break;
    if (!n || n>255) return 0;
    for (j=0;j<i;j++) if (I386NameEqual(bindings[i].name,bindings[j].name)) return 0;
  }
  for (name_size=0;name_size<=255;name_size++)
    if (!entry_name[name_size]) break;
  if (!name_size || name_size>255) return 0;
  for (i=0;i<count;i++) {
    if (!I386ModuleValid(modules[i],sizes[i])) return 0;
    h=modules[i]; total+=h->code_size;
    if (total>U32_MAX) return 0;
  }
  address=load_address; if(address<0) address=(image+0)(U64);
  if(load_address>=0 && address>0x100000000-total) return 0;
  I386SymbolIndexBuild(&index,modules,count);
  entry=I386IndexedSymbol(&index,modules,count,entry_name,I386_MODULE_EXPORT,&matches);
  if (matches!=1) return 0;
  for (i=0;i<count;i++) {
    h=modules[i]; r=modules[i]+h->records_offset;
    for (j=0;j<h->record_count;j++,r++) {
      if (r->kind==I386_MODULE_DATA_RANGE) goto validate_next;
      if (r->kind==I386_MODULE_POINTER) { pointers=TRUE; goto validate_next; }
      target=I386BoundSymbol(modules,count,modules[i]+r->name_offset,0,&matches,
        bindings,binding_count,address,&index);
      if (matches!=1) return 0;
      if (r->kind==I386_MODULE_NAMED_POINTER) {
        pointers=TRUE;
        if (address+target<1 || address+target>U32_MAX) return 0;
      }
      if (r->kind==I386_MODULE_REL32) {
        I386BoundSymbol(modules,count,modules[i]+r->name_offset,I386_MODULE_EXPORT,&matches,bindings,binding_count,address,&index);
        if (matches!=1) return 0;
      }
validate_next:
    }
  }
  if (!image) {
    if (capacity) return 0;
    return total;
  }
  if ((pointers || binding_count) && address>0x100000000-total) return 0;
  if (capacity<total ||
      sizeof(U8 *)==4 && (image+0)(U64)>0x100000000-total ||
      (image+0)(U64)>0xFFFFFFFFFFFFFFFF-total) return 0;
  if (I386BuffersOverlap(image,total,modules,count*sizeof(U8 *)) ||
      I386BuffersOverlap(image,total,sizes,count*8) ||
      I386BuffersOverlap(image,total,entry_name,name_size+1)) return 0;
  for (i=0;i<count;i++)
    if (I386BuffersOverlap(image,total,modules[i],sizes[i])) return 0;
  if (binding_count) {
    if (I386BuffersOverlap(image,total,bindings,binding_count*sizeof(CI386ModuleBinding))) return 0;
    for (k=0;k<binding_count;k++) {
      n=0; while (bindings[k].name[n]) n++;
      if (I386BuffersOverlap(image,total,bindings[k].name,n+1) ||
          ((bindings[k].address+0)(U64)>=(image+0)(U64) &&
           (bindings[k].address+0)(U64)-(image+0)(U64)<total)) return 0;
    }
  }
  //No writes above this point, including on malformed or unresolved input.
  image[0]=0xE9; (image+1)(U32 *)[0]=entry-5;
  image[5]=0; image[6]=0; image[7]=0;
  base=8;
  for (i=0;i<count;i++) {
    h=modules[i];
    for (j=0;j<h->code_size;j++) image[base+j]=modules[i][32+j];
    r=modules[i]+h->records_offset;
    for (j=0;j<h->record_count;j++,r++) {
      if (r->kind==I386_MODULE_POINTER)
        (image+base+r->offset)(U32 *)[0]=address+base+r->name_offset;
      else if (r->kind==I386_MODULE_NAMED_POINTER) {
        target=I386BoundSymbol(modules,count,modules[i]+r->name_offset,0,
          &matches,bindings,binding_count,address,&index);
        (image+base+r->offset)(U32 *)[0]=address+target;
      }
      else if (r->kind==I386_MODULE_REL32 || r->kind==I386_MODULE_ADDRESS) {
        target=I386BoundSymbol(modules,count,modules[i]+r->name_offset,0,&matches,bindings,binding_count,address,&index);
        patch=base+r->offset;
        (image+patch)(U32 *)[0]=target-(patch+4);
      }
    }
    base+=h->code_size;
  }
  return total;
}

public I64 I386LoadBoundInto(U8 **modules,I64 *sizes,I64 count,U8 *image,
  I64 capacity,U8 *entry_name,CI386ModuleBinding *bindings,I64 binding_count)
{//Runtime images use their actual destination address.
  return I386LoadBoundAt(modules,sizes,count,image,capacity,entry_name,bindings,binding_count,-1);
}

public I64 I386LoadInto(U8 **modules,I64 *sizes,I64 count,U8 *image,
  I64 capacity,U8 *entry_name)
{//Existing API keeps module-only resolution and calling convention.
  return I386LoadBoundInto(modules,sizes,count,image,capacity,entry_name,0,0);
}
