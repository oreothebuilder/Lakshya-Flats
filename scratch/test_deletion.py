import urllib.request, json

apiKey = 'AIzaSyASkAtM4zYs8sDR9LPeSPzPsEUMw3rKsVM'
auth_url = f'https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key={apiKey}'
payload = json.dumps({'email': 'damndude159@gmail.com', 'password': 'Admin@123', 'returnSecureToken': True}).encode('utf-8')
req = urllib.request.Request(auth_url, data=payload, headers={'Content-Type': 'application/json'})
with urllib.request.urlopen(req) as resp:
    res = json.loads(resp.read().decode('utf-8'))
    uid = res['localId']
    token = res['idToken']
    print('UID:', uid)

headers = {'Authorization': f'Bearer {token}', 'Content-Type': 'application/json'}

# Test 1: patch users/{uid}
u1 = f'https://firestore.googleapis.com/v1/projects/lakshya-flats/databases/(default)/documents/users/{uid}?updateMask.fieldPaths=deletionRequested&updateMask.fieldPaths=deletionReason'
b1 = json.dumps({'fields': {'deletionRequested': {'booleanValue': True}, 'deletionReason': {'stringValue': 'testing'}}}).encode('utf-8')
req1 = urllib.request.Request(u1, data=b1, headers=headers, method='PATCH')
try:
    with urllib.request.urlopen(req1) as r1:
        print('Test 1 (users/uid) SUCCESS')
except Exception as e:
    print('Test 1 (users/uid) ERROR:', e)

# Test 2: patch students/STU-100006
u2 = f'https://firestore.googleapis.com/v1/projects/lakshya-flats/databases/(default)/documents/students/STU-100006?updateMask.fieldPaths=deletionRequested&updateMask.fieldPaths=deletionReason'
b2 = json.dumps({'fields': {'deletionRequested': {'booleanValue': True}, 'deletionReason': {'stringValue': 'testing'}}}).encode('utf-8')
req2 = urllib.request.Request(u2, data=b2, headers=headers, method='PATCH')
try:
    with urllib.request.urlopen(req2) as r2:
        print('Test 2 (students/STU-100006) SUCCESS')
except Exception as e:
    print('Test 2 (students/STU-100006) ERROR:', e)

# Test 2b: patch users/STU-100006
u2b = f'https://firestore.googleapis.com/v1/projects/lakshya-flats/databases/(default)/documents/users/STU-100006?updateMask.fieldPaths=deletionRequested&updateMask.fieldPaths=deletionReason'
req2b = urllib.request.Request(u2b, data=b2, headers=headers, method='PATCH')
try:
    with urllib.request.urlopen(req2b) as r2b:
        print('Test 2b (users/STU-100006) SUCCESS')
except Exception as e:
    print('Test 2b (users/STU-100006) ERROR:', e)

# Test 3: write account_deletion_requests/{uid}
u3 = f'https://firestore.googleapis.com/v1/projects/lakshya-flats/databases/(default)/documents/account_deletion_requests/{uid}'
b3 = json.dumps({'fields': {'status': {'stringValue': 'Pending'}, 'reason': {'stringValue': 'testing'}}}).encode('utf-8')
req3 = urllib.request.Request(u3, data=b3, headers=headers, method='PATCH')
try:
    with urllib.request.urlopen(req3) as r3:
        print('Test 3 (account_deletion_requests/{uid}) SUCCESS')
except Exception as e:
    print('Test 3 (account_deletion_requests/{uid}) ERROR:', e)

# Test 4: write admin_todos
u4 = 'https://firestore.googleapis.com/v1/projects/lakshya-flats/databases/(default)/documents/admin_todos'
b4 = json.dumps({'fields': {'title': {'stringValue': 'Test Todo'}, 'category': {'stringValue': 'Urgent'}}}).encode('utf-8')
req4 = urllib.request.Request(u4, data=b4, headers=headers, method='POST')
try:
    with urllib.request.urlopen(req4) as r4:
        print('Test 4 (admin_todos) SUCCESS')
except Exception as e:
    print('Test 4 (admin_todos) ERROR:', e)
