"""Generates a synthetic retail dataset (customers, products, stores, orders).

Everything here is made up - it exists so the SQL and Power BI parts of this
project have something realistic to chew on. Two full years of orders,
2024-01-01 through 2025-12-31.
"""
import csv
import random
from datetime import date, timedelta
from pathlib import Path

random.seed(42)
OUT = Path(__file__).parent

FIRST_NAMES = ["Aarav", "Priya", "Liam", "Sofia", "Noah", "Aisha", "Lucas",
               "Mia", "Arjun", "Zara", "Ethan", "Ishaan", "Ava", "Kabir",
               "Riya", "Mason", "Anaya", "Logan", "Diya", "Olivia"]
LAST_NAMES = ["Sharma", "Patel", "Chen", "Khan", "Garcia", "Singh", "Kim",
              "Nguyen", "Murphy", "Silva", "Brown", "Kaur", "Lopez", "Ali",
              "Reddy", "Wilson", "Das", "Taylor", "Nair", "Moore"]

PRODUCTS = [
    # (sku, name, category, subcategory, unit_price)
    ("EL-1001", "Wireless Headphones", "Electronics", "Audio", 129.99),
    ("EL-1002", "Bluetooth Speaker", "Electronics", "Audio", 79.99),
    ("EL-1003", "Smart Watch", "Electronics", "Wearables", 249.99),
    ("EL-1004", "USB-C Charger Kit", "Electronics", "Accessories", 34.99),
    ("EL-1005", "Laptop Stand", "Electronics", "Accessories", 59.99),
    ("AP-2001", "Denim Jacket", "Apparel", "Outerwear", 89.99),
    ("AP-2002", "Cotton T-Shirt", "Apparel", "Tops", 24.99),
    ("AP-2003", "Running Shoes", "Apparel", "Footwear", 119.99),
    ("AP-2004", "Wool Sweater", "Apparel", "Tops", 69.99),
    ("HM-3001", "Ceramic Dinner Set", "Home", "Kitchen", 149.99),
    ("HM-3002", "Table Lamp", "Home", "Decor", 49.99),
    ("HM-3003", "Bedsheet Set", "Home", "Bedding", 79.99),
    ("SP-4001", "Yoga Mat", "Sports", "Fitness", 39.99),
    ("SP-4002", "Dumbbell Pair 15lb", "Sports", "Fitness", 89.99),
    ("SP-4003", "Insulated Water Bottle", "Sports", "Outdoor", 29.99),
]

STORES = [
    # (store_id, name, city, region)
    ("S01", "Downtown Flagship", "Toronto", "East"),
    ("S02", "Northgate Mall", "Toronto", "East"),
    ("S03", "Harbourfront", "Vancouver", "West"),
    ("S04", "Westbrook Centre", "Calgary", "West"),
    ("S05", "Online", "Online", "Online"),
]


def gen_customers(n=800):
    rows = []
    for i in range(1, n + 1):
        name = f"{random.choice(FIRST_NAMES)} {random.choice(LAST_NAMES)}"
        segment = random.choices(["Regular", "Premium", "Budget"],
                                 weights=[0.6, 0.15, 0.25])[0]
        signup = date(2022, 1, 1) + timedelta(days=random.randint(0, 1095))
        rows.append([f"C{i:05d}", name, segment, signup.isoformat()])
    return rows


def gen_orders(customers, n=6000):
    start = date(2024, 1, 1)
    rows = []
    for i in range(1, n + 1):
        # realistic seasonality: Nov/Dec spike, Feb dip
        day_offset = random.randint(0, 729)
        order_date = start + timedelta(days=day_offset)
        month = order_date.month
        seasonal = 1.6 if month in (11, 12) else (0.7 if month == 2 else 1.0)
        if random.random() > seasonal / 1.6:
            continue
        cust = random.choice(customers)[0]
        store = random.choices(STORES, weights=[0.2, 0.2, 0.15, 0.15, 0.3])[0][0]
        # 1-4 line items per order
        for _ in range(random.randint(1, 4)):
            sku, _, _, _, price = random.choice(PRODUCTS)
            qty = random.randint(1, 3)
            discount = random.choice([0, 0, 0, 0.1, 0.15])
            rows.append([f"O{i:06d}", cust, store, sku, qty,
                         f"{price:.2f}", f"{discount:.2f}",
                         order_date.isoformat()])
    return rows


def write_csv(path, header, rows):
    with open(path, "w", newline="") as f:
        w = csv.writer(f)
        w.writerow(header)
        w.writerows(rows)
    print(f"wrote {path} ({len(rows)} rows)")


def main():
    customers = gen_customers()
    write_csv(OUT / "customers.csv",
              ["customer_id", "customer_name", "segment", "signup_date"],
              customers)
    write_csv(OUT / "products.csv",
              ["sku", "product_name", "category", "subcategory", "unit_price"],
              [[s, n, c, sc, f"{p:.2f}"] for s, n, c, sc, p in PRODUCTS])
    write_csv(OUT / "stores.csv",
              ["store_id", "store_name", "city", "region"],
              [list(s) for s in STORES])
    orders = gen_orders(customers)
    write_csv(OUT / "orders.csv",
              ["order_id", "customer_id", "store_id", "sku", "quantity",
               "unit_price", "discount", "order_date"],
              orders)


if __name__ == "__main__":
    main()
