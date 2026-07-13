import os
import time
import random
from datetime import datetime

import psycopg2
from dotenv import load_dotenv

load_dotenv()

conn = psycopg2.connect(
    host=os.getenv("DB_HOST"),
    port=os.getenv("DB_PORT"),
    database=os.getenv("DB_NAME"),
    user=os.getenv("DB_USER"),
    password=os.getenv("DB_PASSWORD")
)

conn.autocommit = True
cursor = conn.cursor()

PAYMENT_METHODS = [
    "credit_card",
    "paypal",
    "apple_pay",
    "google_pay"
]

ORDER_STATUSES = [
    "completed",
    "processing",
    "shipped"
]

while True:

    customer_id = random.randint(1, 500)

    num_items = random.randint(1, 4)

    products = []

    total_amount = 0

    for _ in range(num_items):
        product_id = random.randint(1, 200)

        cursor.execute(
            """
            SELECT base_price_usd
            FROM products
            WHERE product_id = %s
            """,
            (product_id,)
        )

        unit_price = float(cursor.fetchone()[0])

        quantity = random.randint(1, 3)

        total_amount += unit_price * quantity

        products.append(
            (product_id, quantity, unit_price)
        )

    cursor.execute(
        """
        INSERT INTO orders
        (customer_id, order_ts, status, total_amount)
        VALUES (%s,%s,%s,%s)
        RETURNING order_id
        """,
        (
            customer_id,
            datetime.utcnow(),
            random.choice(ORDER_STATUSES),
            total_amount
        )
    )

    order_id = cursor.fetchone()[0]

    for product_id, quantity, unit_price in products:
        cursor.execute(
            """
            INSERT INTO order_items
            (order_id, product_id, quantity, unit_price)
            VALUES (%s,%s,%s,%s)
            """,
            (
                order_id,
                product_id,
                quantity,
                unit_price
            )
        )

    cursor.execute(
        """
        INSERT INTO payments
        (order_id, payment_method, paid_ts, amount)
        VALUES (%s,%s,%s,%s)
        """,
        (
            order_id,
            random.choice(PAYMENT_METHODS),
            datetime.utcnow(),
            total_amount
        )
    )

    print(
        f"Created order {order_id} "
        f"for customer {customer_id} "
        f"amount={total_amount:.2f}"
    )

    time.sleep(60)