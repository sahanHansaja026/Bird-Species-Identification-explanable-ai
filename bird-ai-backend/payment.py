import os
import stripe

from fastapi import APIRouter, Request, HTTPException
from dotenv import load_dotenv
from firebase.firebase_admin import firestore
from datetime import datetime, timezone

load_dotenv()

router = APIRouter()

# =========================
# STRIPE CONFIG
# =========================

stripe.api_key = os.getenv("STRIPE_API_KEY")
WEBHOOK_SECRET = os.getenv("STRIPE_WEBHOOK_SECRET")

# =========================
# FIRESTORE
# =========================

db = firestore.client()


# =========================
# STRIPE WEBHOOK
# =========================

@router.post("/payment/webhook")
async def stripe_webhook(request: Request):

    payload = await request.body()

    signature = request.headers.get("stripe-signature")

    if not signature:
        raise HTTPException(
            status_code=400,
            detail="Missing Stripe signature"
        )

    # =========================
    # VERIFY STRIPE EVENT
    # =========================

    try:
        event = stripe.Webhook.construct_event(
            payload,
            signature,
            WEBHOOK_SECRET
        )

    except ValueError:
        raise HTTPException(
            status_code=400,
            detail="Invalid payload"
        )

    except stripe.error.SignatureVerificationError:
        raise HTTPException(
            status_code=400,
            detail="Invalid Stripe signature"
        )

    # =========================
    # CHECK EVENT
    # =========================

    if event["type"] == "checkout.session.completed":

        session = event["data"]["object"]

        # Firebase UID
        uid = getattr(
            session,
            "client_reference_id",
            None
        )

        print("================================")
        print("Stripe payment completed")
        print("Firebase UID:", uid)
        print("================================")

        if not uid:
            print("ERROR: No client_reference_id found")

            return {
                "success": False,
                "message": "No Firebase UID found"
            }

        # Current time
        now = datetime.now(timezone.utc)

        # =========================
        # UPDATE USERS COLLECTION
        # =========================

        user_ref = db.collection("users").document(uid)

        user_doc = user_ref.get()

        if user_doc.exists:

            user_ref.update({
                "plan": "premium",
                "active": True,
                "updatedAt": now
            })

            print("Updated users collection")

        else:

            user_ref.set({
                "userId": uid,
                "plan": "premium",
                "active": True,
                "updatedAt": now
            })

            print("Created user in users collection")

        # =========================
        # UPDATE SUBSCRIPTIONS COLLECTION
        # =========================

        subscription_ref = (
            db.collection("subscriptions")
            .document(uid)
        )

        subscription_ref.set({
            "userId": uid,
            "plan": "premium",
            "active": True,
            "paymentStatus": "paid",
            "stripeSessionId": session.id,
            "updatedAt": now
        }, merge=True)

        print("Updated subscriptions collection")

        # =========================
        # VERIFY USERS
        # =========================

        updated_user = user_ref.get()

        if updated_user.exists:
            print(
                "USERS DATA:",
                updated_user.to_dict()
            )

        # =========================
        # VERIFY SUBSCRIPTION
        # =========================

        updated_subscription = subscription_ref.get()

        if updated_subscription.exists:
            print(
                "SUBSCRIPTION DATA:",
                updated_subscription.to_dict()
            )

        print("================================")
        print("PREMIUM ACTIVATED SUCCESSFULLY")
        print("================================")

    # =========================
    # OTHER EVENTS
    # =========================

    elif event["type"] == "checkout.session.expired":

        print("Checkout session expired")

    elif event["type"] == "payment_intent.payment_failed":

        print("Payment failed")

    # =========================
    # RESPONSE
    # =========================

    return {
        "success": True
    }

