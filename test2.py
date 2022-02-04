#!/usr/bin/python3

import os
import subprocess
from pathlib import Path

def AD_users():
    print("===adding AD users and groups breadcrumb===")
    ad_dir = (os.getenv('HOME')+'/usr/local/samba/bin/samba-tool')
    path = Path(ad_dir)
    if path.is_file():
        print(f'The samba directory exits'+'\n'+"adding honey users and groups to AD")
        output = subprocess.call(['ad_user.sh'])
        print('AD users and groups added successfully')
    else:
        print('AD not present')
