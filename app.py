from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
import numpy as np
import pandas as pd
from tensorflow.keras.models import load_model
import joblib
import yfinance as yf
import requests
from bs4 import BeautifulSoup
import re
from datetime import datetime, timedelta
import random
from pydantic import BaseModel

# ==============================
# DUMMY USERS
# ==============================
USERS = {
    "admin": "admin",
    "user@gold.app": "gold1234",
}

class LoginRequest(BaseModel):
    username: str
    password: str


app = FastAPI(
    title="Gold Price Prediction API",
    description="API for predicting the future gold price based on live market data.",
    version="3.0.0"
)

# CORS setup
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ==============================
# LOAD MODEL & SCALERS
# ==============================
try:
    model = load_model("models/gold_lstm_model.keras", compile=False)
    feature_scaler = joblib.load("models/feature_scaler.pkl")
    gold_scaler = joblib.load("models/gold_scaler.pkl")

    csv_path = "data/processed/gold_lstm_features_clean.csv"
    historical_df = pd.read_csv(csv_path)
    historical_df.columns = historical_df.columns.str.strip()
    historical_df['Date'] = pd.to_datetime(historical_df['Date'])
    historical_df.set_index('Date', inplace=True)

    print("✅ Model, scalers and data loaded successfully")

except Exception as e:
    import traceback
    traceback.print_exc()
    model = None
    feature_scaler = None
    gold_scaler = None
    historical_df = pd.DataFrame()


# ==============================
# AKGSMA SCRAPER - with 1 hour cache
# ==============================
_gold_cache = {"price": None, "fetched_at": None}

def get_precise_gold_price():
    """Fetch Kerala gold prices from AKGSMA, cached for 1 hour."""
    global _gold_cache

    if _gold_cache["fetched_at"] and _gold_cache["price"]:
        age_seconds = (datetime.now() - _gold_cache["fetched_at"]).seconds
        if age_seconds < 3600:
            print("[AKGSMA] Returning cached price")
            return _gold_cache["price"]

    try:
        import cloudscraper
        scraper = cloudscraper.create_scraper()
        r = scraper.get("https://akgsma.com/", timeout=10)
        r.raise_for_status()
        soup = BeautifulSoup(r.text, "html.parser")

        prices = {}
        for tag in soup.find_all("li"):
            text = tag.get_text()
            if "22K" in text:
                match = re.search(r'₹\s*([\d,]+)', text)
                if match:
                    prices["22k"] = float(match.group(1).replace(",", ""))
            elif "18K" in text:
                match = re.search(r'₹\s*([\d,]+)', text)
                if match:
                    prices["18k"] = float(match.group(1).replace(",", ""))

        if "22k" in prices:
            prices["24k"] = round(prices["22k"] / 0.916, 2)

        if prices:
            _gold_cache["price"] = prices
            _gold_cache["fetched_at"] = datetime.now()
            print(f"[AKGSMA] Fetched: 22K=₹{prices['22k']}/g  24K=₹{prices.get('24k')}/g")
            return prices
        else:
            print("[AKGSMA] No prices found in page")

    except Exception as e:
        print(f"[AKGSMA] Failed: {e}")

    return None


# ==============================
# LIVE DATA FETCH
# ==============================
def fetch_live_data():
    baseline_df = historical_df.copy()

    precise_prices = get_precise_gold_price()

    try:
        last_date = historical_df.index[-1]
        start_date = last_date + timedelta(days=1)
        end_date = datetime.now() + timedelta(days=1)

        if start_date < end_date:
            gold = yf.download("GC=F", start=start_date, end=end_date)
            usd  = yf.download("DX-Y.NYB", start=start_date, end=end_date)
            inr  = yf.download("USDINR=X", start=start_date, end=end_date)

            def get_close(df):
                if 'Close' in df:
                    c = df['Close']
                    return c.iloc[:, 0] if isinstance(c, pd.DataFrame) else c
                return pd.Series(dtype=float)

            merged = pd.concat([
                get_close(gold),
                get_close(usd),
                get_close(inr)
            ], axis=1)

            merged.columns = ['gold', 'usd', 'inr']
            merged.ffill(inplace=True)
            merged.dropna(inplace=True)

            rows = []
            for _, row in merged.iterrows():
                usd_inr = row['inr'] if not pd.isna(row['inr']) else 85.0
                # USD per ounce → INR per 10 grams
                gold_inr = (row['gold'] / 31.1035) * usd_inr * 10

                rows.append({
                    'Gold_Close': gold_inr,
                    'USD_Close': row['usd'],
                    'avg_sentiment': random.uniform(-0.1, 0.1),
                    'news_count': random.randint(40, 120),
                    'Gold_7day_MA': 0,
                    'Gold_30day_MA': 0,
                    'USD_7day_MA': 0
                })

            gap_df = pd.DataFrame(rows, index=merged.index)
            baseline_df = pd.concat([baseline_df, gap_df])
            baseline_df = baseline_df[~baseline_df.index.duplicated()].sort_index()

        # Recalculate MAs on full dataset
        baseline_df['Gold_7day_MA']  = baseline_df['Gold_Close'].rolling(7).mean()
        baseline_df['Gold_30day_MA'] = baseline_df['Gold_Close'].rolling(30).mean()
        baseline_df['USD_7day_MA']   = baseline_df['USD_Close'].rolling(7).mean()

    except Exception as e:
        print(f"Warning: Could not bridge data gap: {e}")

    df = baseline_df.dropna().tail(60)

    # Override latest Gold_Close with scraped 24K price if available
    if precise_prices and not df.empty and '24k' in precise_prices:
        price_10g_24k = precise_prices['24k'] * 10
        df.loc[df.index[-1], 'Gold_Close'] = price_10g_24k
        print(f"[LOG] Overriding Gold_Close with AKGSMA 24K price: ₹{price_10g_24k}")

    return df[['Gold_Close', 'USD_Close', 'avg_sentiment',
               'news_count', 'Gold_7day_MA', 'Gold_30day_MA', 'USD_7day_MA']]


# ==============================
# ROUTES
# ==============================
@app.get("/")
def read_root():
    return {"status": "ok", "message": "Live Gold Price Prediction API is running"}


@app.get("/history")
def history(days: int = 30):
    if days < 1 or days > 1000:
        raise HTTPException(status_code=400, detail="Invalid days")

    try:
        result = []
        for date, row in historical_df.tail(days).iterrows():
            price_10g = float(row["Gold_Close"])
            result.append({
                "date": date.strftime("%Y-%m-%d"),
                "gold_price_10g_24k": round(price_10g, 2),
                "kerala_pavan_22k": round(price_10g * 0.8 * 0.916, 2)
            })
        return {"history": result}

    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@app.get("/current")
def get_current_price():
    try:
        df = fetch_live_data()
        if df.empty:
            raise HTTPException(status_code=500, detail="No data available")

        last = df.iloc[-1]
        price_10g = float(last["Gold_Close"])

        pavan = price_10g * 0.8 * 0.916

        precise_prices = get_precise_gold_price()
        if precise_prices and '22k' in precise_prices:
            pavan = precise_prices['22k'] * 8
            print(f"[LOG] Pavan overridden with AKGSMA 22K price: ₹{pavan}")

        return {
            "gold_price_10g_24k": round(price_10g, 2),
            "kerala_pavan_22k": round(pavan, 2),
            "usd_price": float(last["USD_Close"])
        }

    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@app.post("/login")
def login(req: LoginRequest):
    username = req.username.strip()
    password = req.password.strip()

    if username in USERS and USERS[username] == password:
        return {
            "success": True,
            "message": "Login successful",
            "username": username
        }

    raise HTTPException(status_code=401, detail="Invalid username or password")


@app.get("/predict")
def predict(days_ahead: int = 1):
    if model is None or feature_scaler is None or gold_scaler is None:
        raise HTTPException(status_code=500, detail="Model not loaded")

    if not (1 <= days_ahead <= 60):
        raise HTTPException(status_code=400, detail="Invalid days")

    df = fetch_live_data()

    if len(df) < 60:
        raise HTTPException(status_code=500, detail="Not enough data")

    cols = ['Gold_Close', 'USD_Close', 'avg_sentiment',
            'news_count', 'Gold_7day_MA', 'Gold_30day_MA', 'USD_7day_MA']

    current_df = df[cols].copy()
    preds = []

    for _ in range(days_ahead):
        last_60 = current_df.tail(60).values

        # Use feature_scaler for input scaling
        scaled = feature_scaler.transform(last_60)
        X = scaled.reshape(1, 60, 7).astype('float32')

        # Predict (scaled)
        pred_scaled = model(X, training=False).numpy()

        # Use gold_scaler for inverse transform
        pred_price = gold_scaler.inverse_transform(pred_scaled)[0][0]
        preds.append(float(pred_price))

        # Append predicted row for multi-day prediction
        last_row = current_df.iloc[-1]
        new_row = [pred_price, last_row['USD_Close'], last_row['avg_sentiment'],
                   last_row['news_count'], 0, 0, 0]
        new_df = pd.DataFrame([new_row], columns=cols)
        current_df = pd.concat([current_df, new_df], ignore_index=True)

        # Recalculate MAs
        current_df.loc[current_df.index[-1], 'Gold_7day_MA']  = current_df['Gold_Close'].tail(7).mean()
        current_df.loc[current_df.index[-1], 'Gold_30day_MA'] = current_df['Gold_Close'].tail(30).mean()
        current_df.loc[current_df.index[-1], 'USD_7day_MA']   = current_df['USD_Close'].tail(7).mean()

        current_df = current_df.tail(60)

    return {
        "predictions_10g": [round(p, 2) for p in preds],
        "predictions_pavan": [round(p * 0.8 * 0.916, 2) for p in preds]
    }


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="127.0.0.1", port=8000)