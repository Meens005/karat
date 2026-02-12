import pandas as pd
import matplotlib.pyplot as plt
import os

# Load dataset
file_path = "data/processed/final_dataset_with_news.csv"

if not os.path.exists(file_path):
    print("Dataset not found!")
    exit()

df = pd.read_csv(file_path)

# Convert Date column
df['Date'] = pd.to_datetime(df['Date'])
print(df.columns)
print(df.head())


print("Dataset loaded successfully.")
print(df.head())

# -----------------------------
# Graph 1: Gold Price
# -----------------------------
plt.figure(figsize=(12,6))
plt.plot(df['Date'], df['Gold_USD'])
plt.title("Gold Price Over Time")
plt.xlabel("Date")
plt.ylabel("Gold Price (USD)")
plt.tight_layout()
plt.savefig("filename.png")
plt.close()


# -----------------------------
# Graph 2: Sentiment Over Time
# -----------------------------
plt.figure(figsize=(12,6))
plt.plot(df['Date'], df['avg_sentiment'])
plt.title("Daily Financial Sentiment")
plt.xlabel("Date")
plt.ylabel("Average Sentiment")
plt.tight_layout()
plt.savefig("filename.png")
plt.close()


# -----------------------------
# Graph 3: News Volume
# -----------------------------
# -----------------------------
# Graph 3: News Volume
# -----------------------------
plt.figure(figsize=(12,6))
plt.plot(df['Date'], df['news_count'])
plt.title("Daily Financial News Count")
plt.xlabel("Date")
plt.ylabel("News Count")
plt.tight_layout()
plt.savefig("news_volume.png")
plt.close()
