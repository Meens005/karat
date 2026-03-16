import requests
import json

url = "http://localhost:8000/predict"

payload = {
    "data": []
}

for i in range(30):
    payload["data"].append({
        "Gold_Price": 50000 + i,
        "USD_Price": 96.0 + (i/10),
        "avg_sentiment": -0.05 + (i/1000),
        "news_count": 60 + i
    })

headers = {
    "Content-Type": "application/json"
}

response = requests.post(url, json=payload, headers=headers)
print(response.json())
