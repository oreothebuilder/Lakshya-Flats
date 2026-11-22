import urllib.request, json

apiKey = 'AIzaSyASkAtM4zYs8sDR9LPeSPzPsEUMw3rKsVM'
auth_url = f'https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key={apiKey}'
payload = json.dumps({'email': 'sudhansu1906@gmail.com', 'password': 'Admin@123', 'returnSecureToken': True}).encode('utf-8')
req = urllib.request.Request(auth_url, data=payload, headers={'Content-Type': 'application/json'})
with urllib.request.urlopen(req) as resp:
    res = json.loads(resp.read().decode('utf-8'))
    token = res['idToken']

headers = {'Authorization': f'Bearer {token}', 'Content-Type': 'application/json'}

# 1. Read users/6O68UYicKRYnPNsQevc2olBhFND2
u_auth = 'https://firestore.googleapis.com/v1/projects/lakshya-flats/databases/(default)/documents/users/6O68UYicKRYnPNsQevc2olBhFND2'
with urllib.request.urlopen(urllib.request.Request(u_auth, headers=headers)) as r:
    auth_data = json.loads(r.read().decode('utf-8'))
    fields = auth_data.get('fields', {})
    del_req = fields.get('deletionRequested', {'booleanValue': True})
    del_reason = fields.get('deletionReason', {'stringValue': 'testing'})
    del_time = fields.get('deletionRequestedAt', {'timestampValue': '2026-11-22T12:14:31.235Z'})

# 2. Patch users/STU-100006 with deletion fields
u_stu = 'https://firestore.googleapis.com/v1/projects/lakshya-flats/databases/(default)/documents/users/STU-100006?updateMask.fieldPaths=deletionRequested&updateMask.fieldPaths=deletionReason&updateMask.fieldPaths=deletionRequestedAt'
patch_body = json.dumps({
    'fields': {
        'deletionRequested': del_req,
        'deletionReason': del_reason,
        'deletionRequestedAt': del_time,
    }
}).encode('utf-8')
req_patch = urllib.request.Request(u_stu, data=patch_body, headers=headers, method='PATCH')
with urllib.request.urlopen(req_patch) as r:
    print('Synced deletion fields to users/STU-100006 successfully!')
