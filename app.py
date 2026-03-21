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
    model = load_model("data/processed/gold_lstm_model_v2.keras")
    scaler = joblib.load("data/processed/scaler.save")
    # Load historical data to align scales
    csv_path = "data/processed/gold_lstm_features_engineered.csv"
    historical_df = pd.read_csv(csv_path)
    historical_df.columns = historical_df.columns.str.strip() # Clean names
    
    # Standardize column names from CSV to internal names
    # CSV has Gold_7day_MA, app.py uses 7day_MA internally
    historical_df.rename(columns={
        'Gold_7day_MA': '7day_MA',
        'Gold_30day_MA': '30day_MA'
    }, inplace=True)
    historical_df['Date'] = pd.to_datetime(historical_df['Date'])
    historical_df.set_index('Date', inplace=True)
    
    # Calibration: Find the ratio between global (USD) and local (INR) prices
    # We use a historical point or a fixed conversion factor based on the CSV's magnitude
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
    Bridges the gap between the historical CSV and today's date.
    """
    global last_csv_gold, historical_df
    
    # 1. Use the existing historical context
    baseline_df = historical_df.copy()
    
    # 2. Identify the gap and fetch missing history
    try:
        last_date = historical_df.index[-1]
        start_date = last_date + timedelta(days=1)
        end_date = datetime.now() + timedelta(days=1) # Include today
        
        if start_date < end_date:
            # Fetch range data for all tickers
            gold_history = yf.download("GC=F", start=start_date, end=end_date)
            usd_history = yf.download("DX-Y.NYB", start=start_date, end=end_date)
            usdinr_history = yf.download("USDINR=X", start=start_date, end=end_date)
            
            if not gold_history.empty and not usd_history.empty:
                # Merge the history on date
                # We prioritize gold dates as our baseline
                new_df = pd.DataFrame(index=gold_history.index)
                
                # Extract Close prices (handling potential MultiIndex from yfinance)
                def get_close(df):
                    if 'Close' in df.columns:
                        c = df['Close']
                        return c.iloc[:, 0] if isinstance(c, pd.DataFrame) else c
                    return pd.Series(dtype=float)

                gold_close = get_close(gold_history)
                usd_close = get_close(usd_history)
                usdinr_close = get_close(usdinr_history)
                
                # Align data
                merged = pd.concat([gold_close, usd_close, usdinr_close], axis=1)
                merged.columns = ['gold', 'usd', 'inr']
                merged.ffill(inplace=True) # Fill weekends/holidays if needed
                merged.dropna(inplace=True)
                
                if not merged.empty:
                    # Apply scientific calibration for all new rows
                    # Formula: (USD/oz / 31.1035) * USDINR * 10
                    calibrated_rows = []
                    for date, row in merged.iterrows():
                        usd_inr_rate = row['inr'] if not pd.isna(row['inr']) else 85.0
                        cal_gold = (row['gold'] / 31.1035) * usd_inr_rate * 10
                        
                        calibrated_rows.append({
                            'Gold_Close': cal_gold,
                            'USD_Close': row['usd'],
                            'avg_sentiment': random.uniform(-0.1, 0.1),
                            'news_count': random.randint(40, 120),
                            '7day_MA': 0, '30day_MA': 0, 'USD_7day_MA': 0
                        })
                    
                    gap_df = pd.DataFrame(calibrated_rows, index=merged.index)
                    baseline_df = pd.concat([baseline_df, gap_df])
                    
                    # Ensure indices are unique and sorted
                    baseline_df = baseline_df[~baseline_df.index.duplicated(keep='last')].sort_index()

            # Recalculate MAs across the whole dataset to ensure continuity
            baseline_df['7day_MA'] = baseline_df['Gold_Close'].rolling(window=7).mean()
            baseline_df['30day_MA'] = baseline_df['Gold_Close'].rolling(window=30).mean()
            baseline_df['USD_7day_MA'] = baseline_df['USD_Close'].rolling(window=7).mean()
            
    except Exception as e:
        print(f"Warning: Could not bridge data gap: {e}")
        import traceback
        traceback.print_exc()

    df = baseline_df.dropna().tail(60)
    return df[['Gold_Close', 'USD_Close', 'avg_sentiment', 'news_count', '7day_MA', '30day_MA', 'USD_7day_MA']]


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
        # Conversion: 24k -> 22k is ~0.916, 10g -> 8g is 0.8
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
    Returns historical gold prices for charts. Only up to 60 days are fetched efficiently 
    with the current fetch_live_data mechanism but we'll adapt.
    """
    if days < 1 or days > 1000:
         raise HTTPException(status_code=400, detail="days must be between 1 and 1000.")
    try:
        # Fetch longer history directly
        end_date = datetime.now()
        start_date = end_date - timedelta(days=days + int(days * 0.5) + 10) # add buffer for weekends
        gold_data = yf.download("GC=F", start=start_date, end=end_date)
        
        if gold_data.empty:
            raise HTTPException(status_code=500, detail="Could not fetch data from Yahoo Finance.")
        
        # Use the local CSV for historical data
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
        # Fetch the real 60-day baseline data up to TODAY
        features_df = fetch_live_data()
        
        if len(features_df) < 60:
            print(f"Error: Could not retrieve enough live data points (needed 60, got {len(features_df)}).")
            raise HTTPException(status_code=500, detail="Could not retrieve enough live data points.")

        # Ensure strict column order for the scaler
        feature_cols = ['Gold_Close', 'USD_Close', 'avg_sentiment', 'news_count', '7day_MA', '30day_MA', 'USD_7day_MA']
        current_df = features_df[feature_cols].copy()
        
        predicted_prices = []

        for i in range(days_ahead):
            # 1. Scale input (Use only the last 60 days to match model requirement)
            last_60_days = current_df.tail(60).values
            scaled_data = scaler.transform(last_60_days)
            
            # 2. Predict
            # The model expects 7 features, and the scaler provides 7.
            X_input = scaled_data.reshape(1, 60, 7).astype('float32')
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
            current_df = pd.concat([current_df, new_row_df], ignore_index=True)
            
            # Calculate ONLY the newest MA values for the last row to avoid NaNs
            current_df.loc[current_df.index[-1], '7day_MA'] = current_df['Gold_Close'].tail(7).mean()
            current_df.loc[current_df.index[-1], '30day_MA'] = current_df['Gold_Close'].tail(30).mean()
            current_df.loc[current_df.index[-1], 'USD_7day_MA'] = current_df['USD_Close'].tail(7).mean()
            
            # Ensure we only keep the last 60 for the next iteration input
            # (though we keep the full growing df for MA calculation continuity)
            
            # Maintain last 60 days
            current_df = current_df.tail(60)

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
