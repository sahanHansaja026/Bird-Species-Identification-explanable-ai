import os
import json
import firebase_admin
from firebase_admin import credentials, firestore

firebase_service_account = os.getenv("FIREBASE_SERVICE_ACCOUNT")

if not firebase_service_account:
    raise RuntimeError("FIREBASE_SERVICE_ACCOUNT environment variable is not set")

try:
    service_account_info = json.loads(firebase_service_account)
except json.JSONDecodeError as e:
    raise RuntimeError("FIREBASE_SERVICE_ACCOUNT contains invalid JSON") from e

cred = credentials.Certificate(service_account_info)

if not firebase_admin._apps:
    firebase_admin.initialize_app(cred)

db = firestore.client()