import os
import random
from datetime import date, timedelta

import psycopg2
from faker import Faker
from dotenv import load_dotenv

load_dotenv()

fake = Faker()

conn = psycopg2.connect(
    host=os.getenv("DB_HOST"),
    port=os.getenv("DB_PORT"),
    database=os.getenv("DB_NAME"),
    user=os.getenv("DB_USER"),
    password=os.getenv("DB_PASSWORD")
)

cursor = conn.cursor()

# -----------------------------
# Customers
# -----------------------------

countries = [
    "Egypt",
    "Saudi Arabia",
    "United Arab Emirates",
    "Germany",
    "France",
    "United Kingdom",
    "United States",
    "Canada",
    "India",
    "Turkey"
]

customer_records = []

for _ in range(500):
    signup_date = date.today() - timedelta(
        days=random.randint(0, 1000)
    )

    customer_records.append(
        (
            fake.name(),
            fake.unique.email(),
            random.choice(countries),
            signup_date
        )
    )

cursor.executemany(
    """
    INSERT INTO customers
    (name, email, country, signup_date)
    VALUES (%s, %s, %s, %s)
    """,
    customer_records
)

print("Inserted 500 customers")


# -----------------------------
# Products
# -----------------------------

categories = {
    "Smartphones": [
        "Galaxy", "iPhone", "Pixel", "Redmi", "OnePlus"
    ],
    "Laptops": [
        "ThinkPad", "MacBook", "Inspiron", "Pavilion", "ZenBook"
    ],
    "Accessories": [
        "Mouse", "Keyboard", "Headphones", "Charger", "Webcam"
    ],
    "Gaming": [
        "Gaming Mouse", "Mechanical Keyboard", "Controller", "Monitor"
    ],
    "Smart Home": [
        "Smart Bulb", "Security Camera", "Smart Plug", "Speaker"
    ]
}

product_records = []

for _ in range(200):

    category = random.choice(list(categories.keys()))

    product_name = (
        random.choice(categories[category])
        + " "
        + str(random.randint(100, 999))
    )

    base_price = round(
        random.uniform(10, 2000),
        2
    )

    supplier_id = random.randint(1, 20)

    product_records.append(
        (
            product_name,
            category,
            base_price,
            supplier_id
        )
    )

cursor.executemany(
    """
    INSERT INTO products
    (name, category, base_price_usd, supplier_id)
    VALUES (%s, %s, %s, %s)
    """,
    product_records
)

print("Inserted 200 products")

conn.commit()

cursor.close()
conn.close()

print("Seeding completed successfully.")