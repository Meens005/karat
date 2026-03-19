from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
import numpy as np
import pandas as pd
from tensorflow.keras.models import load_model
import joblib
import yfinance as yf
from datetime import datetime, timedelta
import random

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

# 1. Load the model, scaler, and historical CSV baseline
try:
    model = load_model("data/processed/gold_lstm_model.h5")
    scaler = joblib.load("data/processed/scaler.save")
    # Load historical data to align scales
    csv_path = "data/processed/gold_lstm_features_engineered.csv"
    historical_df = pd.read_csv(csv_path)
    historical_df.columns = historical_df.columns.str.strip() # Clean names
    historical_df['Date'] = pd.to_datetime(historical_df['Date'])
    historical_df.set_index('Date', inplace=True)
    
    last_csv_gold = historical_df['Gold_Close'].iloc[-1]
    last_csv_usdidx = historical_df['USD_Close'].iloc[-1]
    
except Exception as e:
    print(f"Error loading project resources: {e}")
    model = None
    scaler = None
    historical_df = pd.DataFrame()
    last_csv_gold = 0
    last_csv_usdidx = 0

def fetch_live_data():
    """
    Fetches live data and aligns it with the CSV scale (calibration).
    Uses the historical CSV as the base and appends the latest live data point.
    """
    global last_csv_gold, historical_df
    
    # 1. Use the most recent historical context (last 60 days of CSV)
    baseline_df = historical_df.tail(60).copy()
    
    # 2. Fetch today's live price for bridging the gap
    try:
        gold_live = yf.download("GC=F", period="1d")
        usd_live = yf.download("DX=F", period="1d")
        
        if not gold_live.empty and not usd_live.empty:
            # 3. Scientific Conversion (Global USD/oz -> Local INR/10g 24k)
            try:
                usdinr_data = yf.download("USDINR=X", period="1d")
                usd_inr_rate = float(usdinr_data['Close'].iloc[-1])
            except:
                usd_inr_rate = 85.0 # Fallback
                
            current_gold_usd = gold_live['Close']
            if isinstance(current_gold_usd, pd.DataFrame): 
                current_gold_usd = current_gold_usd.iloc[:, 0]
            current_gold_usd = float(current_gold_usd.iloc[-1])
            
            current_usd_val = usd_live['Close']
            if isinstance(current_usd_val, pd.DataFrame):
                current_usd_val = current_usd_val.iloc[:, 0]
            current_usd_val = float(current_usd_val.iloc[-1])
            
            # Formula: (USD/oz / 31.1035) * USDINR * 10
            calibrated_gold = (current_gold_usd / 31.1035) * usd_inr_rate * 10
            calibrated_usd = current_usd_val
            
            new_date = datetime.now()
            new_row = {
                'Gold_Close': calibrated_gold,
                'USD_Close': calibrated_usd,
                'avg_sentiment': random.uniform(-0.1, 0.1),
                'news_count': random.randint(40, 120),
                'gold_ma7': 0, 'gold_ma30': 0, 'usd_ma7': 0
            }
            new_df = pd.DataFrame([new_row], index=[new_date])
            baseline_df = pd.concat([baseline_df, new_df])
            
            # Recalculate MAs including the live point
            baseline_df['gold_ma7'] = baseline_df['Gold_Close'].rolling(window=7).mean()
            baseline_df['gold_ma30'] = baseline_df['Gold_Close'].rolling(window=30).mean()
            baseline_df['usd_ma7'] = baseline_df['USD_Close'].rolling(window=7).mean()
            
    except Exception as e:
        print(f"Warning: Could not fetch real-time update: {e}")
        pass

    df = baseline_df.dropna().tail(30)
    return df[['Gold_Close', 'USD_Close', 'avg_sentiment', 'news_count', 'gold_ma7', 'gold_ma30', 'usd_ma7']]


@app.get("/")
def read_root():
    return {"status": "ok", "message": "Live Gold Price Prediction API is running"}

@app.get("/current")
def get_current_price():
    """
    Returns the most recent available gold price and USD index.
    """
    try:
        df = fetch_live_data()
        if df.empty:
             raise HTTPException(status_code=500, detail="Could not retrieve live data points.")
        last_row = df.iloc[-1]
        price_10g_24k = float(last_row["Gold_Close"])
        # Kerala Standard: 8g (1 Pavan) of 22k Gold
        price_pavan_22k = price_10g_24k * 0.8 * 0.916
        
        return {
            "date": df.index[-1].strftime("%Y-%m-%d"),
            "gold_price_10g_24k": round(price_10g_24k, 2),
            "kerala_gold_pavan_22k": round(price_pavan_22k, 2),
            "usd_price": float(last_row["USD_Close"]),
            "currency": "INR",
            "unit": "8 grams (22k)"
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error fetching current price: {str(e)}")

@app.get("/history")
def get_history(days: int = 30):
    """
    Returns historical gold prices for charts.
    """
    if days < 1 or days > 1000:
         raise HTTPException(status_code=400, detail="days must be between 1 and 1000.")
    try:
        end_date = datetime.now()
        start_date = end_date - timedelta(days=days + int(days * 0.5) + 10)
        gold_data = yf.download("GC=F", start=start_date, end=end_date)
        
        if gold_data.empty:
            raise HTTPException(status_code=500, detail="Could not fetch data from Yahoo Finance.")
        
        df = historical_df.tail(days).copy()
        
        history_list = []
        for date, row in df.iterrows():
            price_10g_24k = float(row["Gold_Close"])
            price_pavan_22k = price_10g_24k * 0.8 * 0.916
            history_list.append({
                "date": date.strftime("%Y-%m-%d"),
                "gold_price_10g_24k": round(price_10g_24k, 2),
                "kerala_gold_pavan_22k": round(price_pavan_22k, 2)
            })
        return {"history": history_list, "currency": "INR", "unit": "8 grams (22k)"}
    except Exception as e:
         raise HTTPException(status_code=500, detail=f"Error fetching history: {str(e)}")

@app.get("/predict")
def predict_gold_price(days_ahead: int = 1):
    """
    Predicts the gold price `days_ahead` into the future using recursive forecasting.
    """
    import pandas as pd
    if model is None or scaler is None:
        raise HTTPException(status_code=500, detail="Model or Scaler not loaded properly.")
    
    if days_ahead < 1 or days_ahead > 60:
         raise HTTPException(status_code=400, detail="days_ahead must be between 1 and 60.")

    try:
        # Fetch the real 30-day baseline data up to TODAY
        features_df = fetch_live_data()
        
        if len(features_df) < 30:
            raise HTTPException(status_code=500, detail="Could not retrieve enough live data points.")

        # Ensure strict column order matching training
        feature_cols = ['Gold_Close', 'USD_Close', 'avg_sentiment', 'news_count', 'gold_ma7', 'gold_ma30', 'usd_ma7']
        current_df = features_df[feature_cols].copy()
        
        predicted_prices = []

        for i in range(days_ahead):
            # 1. Scale input
            scaled_data = scaler.transform(current_df.values)
            
            # 2. Reshape and predict using all 7 features
            X_input = scaled_data.reshape(1, 30, 7).astype('float32')
            scaled_prediction = model(X_input, training=False)
            scaled_prediction = scaled_prediction.numpy()
            
            # 3. Inverse transform (requires 7 columns)
            dummy_array = np.zeros((1, 7))
            dummy_array[0, 0] = scaled_prediction[0][0]
            real_prediction = scaler.inverse_transform(dummy_array)[0, 0]
            predicted_price = float(real_prediction)
            predicted_prices.append(predicted_price)
            
            # 4. Prepare new row
            last_row = current_df.iloc[-1]
            new_row_data = [
                predicted_price, 
                last_row['USD_Close'], 
                last_row['avg_sentiment'], 
                last_row['news_count'],
                0, 0, 0 # Placeholders for MAs
            ]
            new_row_df = pd.DataFrame([new_row_data], columns=feature_cols)
            
            # Append and update moving averages
            current_df = pd.concat([current_df, new_row_df], ignore_index=True)
            current_df['gold_ma7'] = current_df['Gold_Close'].rolling(window=7).mean()
            current_df['gold_ma30'] = current_df['Gold_Close'].rolling(window=30).mean()
            current_df['usd_ma7'] = current_df['USD_Close'].rolling(window=7).mean()
            
            # Maintain last 30 days
            current_df = current_df.tail(30)

        # Convert predictions to Kerala Pavan (8g 22k)
        pavan_predictions = [round(p * 0.8 * 0.916, 2) for p in predicted_prices]

        return {
            "target_days_ahead": days_ahead,
            "predictions_10g_24k": [round(p, 2) for p in predicted_prices],
            "predictions_kerala_pavan_22k": pavan_predictions,
            "currency": "INR",
            "unit_pavan": "8 grams (22k)"
        }
    except Exception as e:
        import traceback
        traceback.print_exc()
        raise HTTPException(status_code=500, detail=f"Prediction error: {str(e)}")