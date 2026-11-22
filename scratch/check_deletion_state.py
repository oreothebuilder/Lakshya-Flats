import urllib.request, json

apiKey = 'AIzaSyASkAtM4zYs8sDR9LPeSPzPsEUMw3rKsVM'
auth_url = f'https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key={apiKey}'
payload = json.dumps({'email': 'sudhansu1906@gmail.com', 'password': 'Admin@123', 'returnSecureToken': True}).encode('utf-8')
req = urllib.request.Request(auth_url, data=payload, headers={'Content-Type': 'application/json'})
with urllib.request.urlopen(req) as resp:
    res = json.loads(resp.read().decode('utf-8'))
    token = res['idToken']

headers = {'Authorization': f'Bearer {token}'}

for doc in ['6O68UYicKRYnPNsQevc2olBhFND2', 'STU-100006']:
    url = f'https://firestore.googleapis.com/v1/projects/lakshya-flats/databases/(default)/documents/users/{doc}'
    try:
        with urllib.request.urlopen(urllib.request.Request(url, headers=headers)) as r:
            data = json.loads(r.read().decode('utf-8'))
            fields = data.get('fields', {})
            print(f'=== users/{doc} ===')
            print('deletionRequested:', fields.get('deletionRequested'))
            print('deletionReason:', fields.get('deletionReason'))
            print('deletionRequestedAt:', fields.get('deletionRequestedAt'))
    except Exception as e:
        print(f'Error reading users/{doc}:', e)

# Also check account_deletion_requests
url_req = 'https://firestore.googleapis.com/v1/projects/lakshya-flats/databases/(default)/documents/account_deletion_requests'
try:
    with urllib.request.urlopen(urllib.request.Request(url_req, headers=headers)) as r:
        data = json.loads(r.read().decode('utf-8'))
        docs = data.get('documents', [])
        print(f'=== account_deletion_requests ({len(docs)} found) ===')
        for d in docs:
            print(d['name'], d.get('fields', {}))
except Exception as e:
    print('Error reading account_deletion_requests:', e)

# Also check admin_todos
url_todo = 'https://firestore.googleapis.com/v1/projects/lakshya-flats/databases/(default)/documents/admin_todos'
try:
    with urllib.request.urlopen(urllib.request.Request(url_todo, headers=headers)) as r:
        data = json.loads(r.read().decode('utf-8'))
        docs = data.get('documents', [])
        print(f'=== admin_todos ({len(docs)} found) ===')
        for d in docs:
            fields = d.get('fields', {})
            if 'deletion' in str(fields).lower():
                print('Deletion Todo:', fields.get('title'), fields.get('description'))
except Exception as e:
    print('Error reading admin_todos:', e)
