import urllib.request, json

apiKey = 'AIzaSyASkAtM4zYs8sDR9LPeSPzPsEUMw3rKsVM'
auth_url = f'https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key={apiKey}'
payload = json.dumps({'email': 'damndude159@gmail.com', 'password': 'Admin@123', 'returnSecureToken': True}).encode('utf-8')
req = urllib.request.Request(auth_url, data=payload, headers={'Content-Type': 'application/json'})
with urllib.request.urlopen(req) as resp:
    res = json.loads(resp.read().decode('utf-8'))
    uid = res['localId']
    token = res['idToken']

headers = {'Authorization': f'Bearer {token}', 'Content-Type': 'application/json'}

# 1. Create account_deletion_requests/{uid}
u = f'https://firestore.googleapis.com/v1/projects/lakshya-flats/databases/(default)/documents/account_deletion_requests/{uid}'
b = json.dumps({'fields': {'status': {'stringValue': 'Pending'}, 'reason': {'stringValue': 'testing cancellation'}}}).encode('utf-8')
req = urllib.request.Request(u, data=b, headers=headers, method='PATCH')
with urllib.request.urlopen(req) as r:
    print('Create request: SUCCESS')

# 2. Delete account_deletion_requests/{uid} (Cancel)
req_del = urllib.request.Request(u, headers=headers, method='DELETE')
try:
    with urllib.request.urlopen(req_del) as r_del:
        print('Delete request (Cancel): SUCCESS')
except Exception as e:
    print('Delete request (Cancel) ERROR:', e)
