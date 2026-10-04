#!/usr/bin/env python3
import base64
import json
import urllib.error
import urllib.request
from pathlib import Path

root = Path(__file__).resolve().parents[1]
values = dict(line.split('=', 1) for line in (root / '.env').read_text().splitlines() if '=' in line and not line.startswith('#'))
opener = urllib.request.build_opener(urllib.request.ProxyHandler({}))
url = 'http://127.0.0.1:8080/job/delivery-lab/api/json'
try:
    opener.open(url, timeout=3)
    raise SystemExit('Anonymous job access is still enabled')
except urllib.error.HTTPError as e:
    if e.code not in (401, 403, 404): raise
headers = {'Authorization': 'Basic ' + base64.b64encode(('hundrik:' + values['JENKINS_ADMIN_PASSWORD']).encode()).decode()}
with opener.open(urllib.request.Request(url, headers=headers), timeout=3) as response:
    assert json.load(response)['name'] == 'delivery-lab'
print('Jenkins job is ready; authentication is required.')
