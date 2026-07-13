import os
import json
import time
import random
import uuid
from datetime import datetime, timezone

from dotenv import load_dotenv
from google.cloud import pubsub_v1

load_dotenv()

PROJECT_ID = os.getenv("GCP_PROJECT_ID")
TOPIC_ID = os.getenv("PUBSUB_TOPIC", "clickstream-events")

NUM_CUSTOMERS = 500
NUM_PRODUCTS = 200

DEVICES = ["mobile", "desktop", "tablet"]

# Probabilities that a session progresses to the next stage
P_ADD_TO_CART = 0.35
P_CHECKOUT_GIVEN_CART = 0.5
P_PURCHASE_GIVEN_CHECKOUT = 0.7

publisher = pubsub_v1.PublisherClient()
topic_path = publisher.topic_path(PROJECT_ID, TOPIC_ID)


def make_event(customer_id, session_id, event_type, product_id, device):
    return {
        "event_id": str(uuid.uuid4()),
        "customer_id": customer_id,
        "session_id": session_id,
        "event_type": event_type,
        "product_id": product_id,
        "timestamp": datetime.now(timezone.utc).isoformat(),
        "device": device,
    }


def publish(event: dict):
    data = json.dumps(event).encode("utf-8")
    future = publisher.publish(topic_path, data)
    future.result()
    print(f"published {event['event_type']} customer={event['customer_id']} product={event['product_id']}")


def simulate_session():
    customer_id = random.randint(1, NUM_CUSTOMERS)
    session_id = str(uuid.uuid4())
    device = random.choice(DEVICES)

    num_views = random.randint(2, 5)
    viewed_products = [random.randint(1, NUM_PRODUCTS) for _ in range(num_views)]

    for product_id in viewed_products:
        publish(make_event(customer_id, session_id, "page_view", product_id, device))
        time.sleep(random.uniform(0.5, 2))

    if random.random() < P_ADD_TO_CART:
        cart_product = random.choice(viewed_products)
        publish(make_event(customer_id, session_id, "add_to_cart", cart_product, device))
        time.sleep(random.uniform(0.5, 1.5))

        if random.random() < P_CHECKOUT_GIVEN_CART:
            publish(make_event(customer_id, session_id, "checkout", cart_product, device))
            time.sleep(random.uniform(0.5, 1.5))

            if random.random() < P_PURCHASE_GIVEN_CHECKOUT:
                publish(make_event(customer_id, session_id, "purchase", cart_product, device))


def main():
    print(f"streaming clickstream events to {topic_path}")
    while True:
        simulate_session()
        # gap between sessions so events arrive at a steady, demo-friendly rate
        time.sleep(random.uniform(2, 6))


if __name__ == "__main__":
    main()