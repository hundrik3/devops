#!/usr/bin/env python3
"""Trigger the local Jenkins job without exposing credentials on the command line."""
import base64
import http.cookiejar
import json
import time
import urllib.parse
import urllib.request
from pathlib import Path

root = Path(__file__).resolve().parents[1]
values = dict(line.split('=', 1) for line in (root / '.env').read_text().splitlines() if '=' in line and not line.startswith('#'))
base = 'http://127.0.0.1:8080'
auth = base64.b64encode(('hundrik:' + values['JENKINS_ADMIN_PASSWORD']).encode()).decode()
opener = urllib.request.build_opener(urllib.request.ProxyHandler({}), urllib.request.HTTPCookieProcessor(http.cookiejar.CookieJar()))
headers = {'Authorization': 'Basic ' + auth}
def get(path):
    with opener.open(urllib.request.Request(base + path, headers=headers), timeout=15) as response:
        return json.load(response)
crumb = get('/crumbIssuer/api/json')
headers[crumb['crumbRequestField']] = crumb['crumb']
parameters = urllib.parse.urlencode({'SOURCE_REPOSITORY': '', 'SOURCE_BRANCH': 'main', 'FORCE_REBUILD': 'true'}).encode()
request = urllib.request.Request(base + '/job/delivery-lab/buildWithParameters', data=parameters, headers=headers)
with opener.open(request, timeout=15) as response:
    queue_path = urllib.parse.urlsplit(response.headers['Location']).path.rstrip('/') + '/api/json'
print('Jenkins build queued', flush=True)
deadline = time.monotonic() + 900
build_path = None
while time.monotonic() < deadline:
    queued = get(queue_path)
    if 'executable' in queued:
        build_path = '/job/delivery-lab/' + str(queued['executable']['number'])
        print('Build #' + str(queued['executable']['number']) + ' started', flush=True)
        break
    if queued.get('cancelled'): raise SystemExit('Build cancelled')
    time.sleep(2)
if build_path is None: raise SystemExit('Queue timeout')
while time.monotonic() < deadline:
    result = get(build_path + '/api/json')
    if not result['building']:
        req = urllib.request.Request(base + build_path + '/consoleText', headers=headers)
        with opener.open(req, timeout=15) as response:
            console = response.read().decode()
        (root / 'evidence' / 'jenkins-console.txt').write_text(console)
        metadata = {k:result[k] for k in ('number', 'result', 'duration', 'timestamp')}
        (root / 'evidence' / 'jenkins-build.json').write_text(json.dumps(metadata, indent=2) + '\n')
        print('Jenkins result:', result['result'], flush=True)
        if result['result'] != 'SUCCESS':
            print('\n'.join(console.splitlines()[-45:]))
            raise SystemExit(1)
        print('\n'.join(console.splitlines()[-15:]))
        break
    time.sleep(3)
else: raise SystemExit('Build timeout')
