import sys
from sqlalchemy import text
from app.database import engine, Base
from app.models.policy import Policy

def main():
    try:
        with engine.begin() as conn:
            conn.execute(text("ALTER TABLE policies ADD COLUMN completed_deliveries INTEGER DEFAULT 0 NOT NULL;"))
            print("Successfully added completed_deliveries column.")
    except Exception as e:
        print("Error:", e)

if __name__ == "__main__":
    main()
