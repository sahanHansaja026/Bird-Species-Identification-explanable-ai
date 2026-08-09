import stripe
from fastapi import APIRouter, Request, HTTPException
from dotenv import load_dotenv
import stripe
from firebase_admin import db
from datetime import datetime, timedelta
import os


router = APIRouter()


load_dotenv()

stripe.api_key = os.getenv("STRIPE_API_KEY")

WEBHOOK_SECRET = os.getenv("STRIPE_WEBHOOK_SECRET")


@router.post("/payment/webhook")
async def stripe_webhook(request: Request):

    payload = await request.body()

    signature = request.headers.get(
        "stripe-signature"
    )


    try:
        event = stripe.Webhook.construct_event(
            payload,
            signature,
            WEBHOOK_SECRET
        )

    except Exception as e:
        raise HTTPException(
            status_code=400,
            detail=str(e)
        )


    if event["type"] == "checkout.session.completed":

        session = event["data"]["object"]

        uid = session.get(
            "client_reference_id"
        )


        if uid:

            db.collection("users") \
            .document(uid) \
            .update({

                "subscription": "premium",

                "paymentStatus": "paid",

                "subscriptionActive": True,

                "updatedAt": datetime.utcnow()

            })


            print(
                "Premium enabled:",
                uid
            )


    return {
        "success": True
    }