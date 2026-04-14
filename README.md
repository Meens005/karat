# Gold Price Prediction using LSTM with News Sentiment (Flutter App)

## Overview

This project predicts **gold prices using LSTM (Long Short-Term Memory)** by incorporating multiple real-world influencing factors:

* Historical Gold Prices
* USD Exchange Rate
* News Sentiment Analysis (Novel Feature)

The prediction system is integrated into a **Flutter mobile application** that allows users to view predicted gold prices interactively.

Dataset Range: **2018 – 2026**

---

## Problem Statement

Gold prices are influenced by various economic, political, and global events. Traditional prediction models rely only on historical price data.

This project improves prediction accuracy by including:

* USD currency fluctuations
* Market sentiment from financial news
* Long-term historical data

This creates a more **robust and real-world prediction model**.

---

## Features

* Gold price prediction using LSTM
* News sentiment-based prediction
* USD exchange rate integration
* Flutter mobile application interface
* Real-world financial forecasting
* Multi-feature time-series prediction

---

## Tech Stack

### Machine Learning

* Python
* TensorFlow / Keras
* Pandas
* NumPy
* Scikit-learn
* Matplotlib

### Mobile Application

* Flutter
* Dart

### Data Processing

* NLP Sentiment Analysis
* Time Series Forecasting

---

## Dataset

The dataset includes:

* Gold prices (2018–2026)
* USD exchange rates (2018–2026)
* News sentiment scores

---

## Methodology

### 1. Data Collection

* Historical gold price data
* USD exchange rate data
* Financial news data

### 2. Data Preprocessing

* Handling missing values
* Normalization
* Time-series formatting

### 3. Sentiment Analysis

* News sentiment scoring
* Integration with dataset

### 4. Model Training

* LSTM Model
* Multi-feature input
* Time-series prediction

### 5. Flutter Integration

* Backend prediction API
* Mobile UI for predictions

---

## Project Structure

data/ → Dataset files
models/ → Trained LSTM models
notebooks/ → Model training notebooks
frontend/ → Flutter mobile app
app.py → Backend prediction API
requirements.txt → Dependencies

---

## Key Innovation

This project introduces:

* News sentiment as prediction feature
* Multi-factor gold prediction
* Mobile-based prediction system
* Long-term dataset (2018–2026)

---

## Future Improvements

* Real-time news scraping
* Live gold price prediction
* Cloud deployment
* Enhanced UI dashboard

---

## How to Run

### Backend

git clone https://github.com/Meens005/karat.git
cd karat
pip install -r requirements.txt
python app.py

---

### Flutter App

cd frontend
flutter pub get
flutter run

---

## Why This Project Stands Out

* Deep Learning (LSTM)
* NLP Sentiment Analysis
* Flutter Mobile App
* Financial Time Series Prediction
* Real-world Application

---


