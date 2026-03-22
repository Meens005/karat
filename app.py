from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
import numpy as np
import pandas as pd
from tensorflow.keras.models import load_model
import joblib
import yfinance as yf
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
    version="2.0.0"
)

# CORS setup
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Load model and data
try:
    
    import pickle
    import joblib
    #model = load_model("data/processed/gold_lstm_model_v2.keras")
    model = load_model("data/processed/gold_lstm_model_v2.keras", compile=False)
    with open("data/processed/scaler.pkl", "rb") as f:
        scaler = pickle.load(f)

    csv_path = "data/processed/gold_lstm_features_engineered.csv"
    historical_df = pd.read_csv(csv_path)
    historical_df.columns = historical_df.columns.str.strip()

    historical_df.rename(columns={
        'Gold_7day_MA': '7day_MA',
        'Gold_30day_MA': '30day_MA'
    }, inplace=True)

    historical_df['Date'] = pd.to_datetime(historical_df['Date'])
    historical_df.set_index('Date', inplace=True)

except Exception as e:
    import traceback
    traceback.print_exc()
    model = None
    scaler = None
    historical_df = pd.DataFrame()

def fetch_live_data():
    baseline_df = historical_df.copy()

    try:
        last_date = historical_df.index[-1]
        start_date = last_date + timedelta(days=1)
        end_date = datetime.now() + timedelta(days=1)

        if start_date < end_date:
            gold = yf.download("GC=F", start=start_date, end=end_date)
            usd = yf.download("DX-Y.NYB", start=start_date, end=end_date)
            inr = yf.download("USDINR=X", start=start_date, end=end_date)

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
                gold_inr = (row['gold'] / 31.1035) * usd_inr * 10

                rows.append({
                    'Gold_Close': gold_inr,
                    'USD_Close': row['usd'],
                    'avg_sentiment': random.uniform(-0.1, 0.1),
                    'news_count': random.randint(40, 120),
                    '7day_MA': 0,
                    '30day_MA': 0,
                    'USD_7day_MA': 0
                })

            gap_df = pd.DataFrame(rows, index=merged.index)
            baseline_df = pd.concat([baseline_df, gap_df])
            baseline_df = baseline_df[~baseline_df.index.duplicated()].sort_index()

        baseline_df['7day_MA'] = baseline_df['Gold_Close'].rolling(7).mean()
        baseline_df['30day_MA'] = baseline_df['Gold_Close'].rolling(30).mean()
        baseline_df['USD_7day_MA'] = baseline_df['USD_Close'].rolling(7).mean()

    except Exception as e:
        print(f"Warning: Could not bridge data gap: {e}")

    df = baseline_df.dropna().tail(60)

    return df[['Gold_Close', 'USD_Close', 'avg_sentiment',
               'news_count', '7day_MA', '30day_MA', 'USD_7day_MA']]


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
    if model is None or scaler is None:
        raise HTTPException(status_code=500, detail="Model not loaded")

    if not (1 <= days_ahead <= 60):
        raise HTTPException(status_code=400, detail="Invalid days")

    df = fetch_live_data()

    if len(df) < 60:
        raise HTTPException(status_code=500, detail="Not enough data")

    cols = [
        'Gold_Close', 'USD_Close',
        'avg_sentiment', 'news_count',
        '7day_MA', '30day_MA', 'USD_7day_MA'
    ]

    current_df = df[cols].copy()
    preds = []

    for _ in range(days_ahead):
        last_60 = current_df.tail(60).values
        scaled = scaler.transform(last_60)

        X = scaled.reshape(1, 60, 7).astype('float32')
        pred_scaled = model(X, training=False).numpy()  # shape (1, 30)

        # inverse transform day 1 prediction
        dummy = np.zeros((1, 7))
        dummy[0, 0] = pred_scaled[0][0]  # first of 30 days
        pred = scaler.inverse_transform(dummy)[0, 0]
        preds.append(float(pred))

        last_row = current_df.iloc[-1]
        new_row = [pred, last_row['USD_Close'], last_row['avg_sentiment'],
                   last_row['news_count'], 0, 0, 0]
        new_df = pd.DataFrame([new_row], columns=cols)
        current_df = pd.concat([current_df, new_df], ignore_index=True)

        current_df.loc[current_df.index[-1], '7day_MA'] = current_df['Gold_Close'].tail(7).mean()
        current_df.loc[current_df.index[-1], '30day_MA'] = current_df['Gold_Close'].tail(30).mean()
        current_df.loc[current_df.index[-1], 'USD_7day_MA'] = current_df['USD_Close'].tail(7).mean()

        current_df = current_df.tail(60)

    return {
        "predictions_10g": [round(p, 2) for p in preds],
        "predictions_pavan": [round(p * 0.8 * 0.916, 2) for p in preds]
    }