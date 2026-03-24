import keras

model = keras.models.load_model("data/processed/gold_lstm_model_v2.keras")
print("Model loaded successfully")