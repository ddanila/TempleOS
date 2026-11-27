"""Validate the complete Budget source, allowing only its reviewed width ports."""
import hashlib
import subprocess
from pathlib import Path

ROOT=Path(__file__).resolve().parents[1]
REPAIRS='ce055f205fc38536443289fb1cfc73632f6624f4'


def installed_budget_directory(before, installed, fixture_path):
    """Locate the guest's configured Budget directory from its cold install."""
    changed = {name for name in before.keys() | installed.keys()
               if before.get(name) != installed.get(name)}
    if fixture_path not in changed or len(changed) != 2:
        raise ValueError(f'Unexpected files changed during Budget install: {sorted(changed)}')
    accounts = (changed - {fixture_path}).pop()
    if (not accounts.endswith('/Budget/Accts.DD.Z') or accounts in before
            or installed[accounts][2] != before['/Apps/Budget/Accts.DD.Z'][2]):
        raise ValueError(f'Budget install did not copy the bundled accounts: {accounts}')
    return accounts.removesuffix('/Accts.DD.Z')


def budget_source(entry):
    name=entry['path']
    original=subprocess.check_output(['git','show',REPAIRS+':'+name],cwd=ROOT)
    if hashlib.sha256(original).hexdigest()!=entry['reference_sha256']:
        raise ValueError('Reference mismatch: '+name)
    if name=='Apps/Budget/BgtStrs.HC':
        old=b'  CHashGeneric *tmph,**a;'
        allocation=b'a=MAlloc(cnt*sizeof(CHashGeneric *));'
        if original.count(old)!=1 or original.count(allocation)!=1:
            raise ValueError('Unexpected Budget sort source')
        return original.replace(old,b'  CHashGeneric *tmph;\n  I64 *a; //QSortI64 sorts eight-byte values, also on 32-bit targets.').replace(allocation,b'a=MAlloc(cnt*sizeof(I64));')
    if name=='Apps/Budget/BgtMain.HC':
        old=b'if ((st=BgtPopUpAcct("View Acct\\n\\n",view_acct))>=0)'
        if original.count(old)!=1:raise ValueError('Unexpected Budget view picker source')
        return original.replace(old,b'if ((st=BgtPopUpAcct("View Acct\\n\\n",view_acct))!=DOCM_CANCEL(U8 *))')
    if name=='Apps/Budget/BgtEntry.HC':
        old=b'if (st!=DOCM_CANCEL)'
        if original.count(old)!=2:raise ValueError('Unexpected Budget entry picker source')
        return original.replace(old,b'if (st!=DOCM_CANCEL(U8 *))')
    return original
