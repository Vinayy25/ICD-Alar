import os
import json
import requests
import redis
import asyncio
from datetime import datetime, timedelta
from fastapi import FastAPI, HTTPException, BackgroundTasks
from typing import List, Dict, Any
from dotenv import load_dotenv

load_dotenv()

client_id = os.getenv("ICD_CLIENT_ID")
client_secret = os.getenv("ICD_CLIENT_SECRET")

app = FastAPI()
ICD_BASE_URL = "https://id.who.int/icd"

# Initialize the Redis client
redis_client = redis.Redis(host='localhost', port=6379, db=0, decode_responses=True)

# Add these global variables
CURRENT_TOKEN = None
LAST_TOKEN_REFRESH = None
TOKEN_REFRESH_INTERVAL = timedelta(minutes=15)

async def refresh_token_periodically():
    """Background task to refresh the token every 15 minutes"""
    global CURRENT_TOKEN, LAST_TOKEN_REFRESH
    while True:
        try:
            CURRENT_TOKEN = fetch_token()
            LAST_TOKEN_REFRESH = datetime.now()
            print(f"Token refreshed at: {LAST_TOKEN_REFRESH}")
            await asyncio.sleep(TOKEN_REFRESH_INTERVAL.total_seconds())
        except Exception as e:
            print(f"Error refreshing token: {e}")
            await asyncio.sleep(60)  # Wait a minute before retrying on error

async def get_valid_token() -> str:
    """Get a valid token, refreshing if necessary"""
    global CURRENT_TOKEN, LAST_TOKEN_REFRESH
    
    if CURRENT_TOKEN is None or LAST_TOKEN_REFRESH is None:
        CURRENT_TOKEN = fetch_token()
        LAST_TOKEN_REFRESH = datetime.now()
    elif datetime.now() - LAST_TOKEN_REFRESH >= TOKEN_REFRESH_INTERVAL:
        CURRENT_TOKEN = fetch_token()
        LAST_TOKEN_REFRESH = datetime.now()
    
    return CURRENT_TOKEN

def fetch_token() -> str:
    scope = 'icdapi_access'
    grant_type = 'client_credentials'
    token_endpoint = "https://icdaccessmanagement.who.int/connect/token"

    payload = {
        'client_id': client_id, 
        'client_secret': client_secret, 
        'scope': scope, 
        'grant_type': grant_type
    }
    r = requests.post(token_endpoint, data=payload, verify=False).json()
    print(r)
    token = r['access_token']
    return token

async def fetch_icd_data(endpoint: str) -> Dict[str, Any]:
    """
    Generic function to fetch data from the ICD API using the given endpoint.
    This function is not cached.
    """
    token = await get_valid_token()
    headers = {
        "Authorization": f"Bearer {token}",
        "Accept": "application/json",
        "Accept-Language": "en",
        "API-Version": "v2",
    }
    try:
        response = requests.get(f"{ICD_BASE_URL}/{endpoint}", headers=headers)
        response.raise_for_status()
        return response.json()
    except requests.exceptions.RequestException as e:
        raise HTTPException(status_code=500, detail=f"Error fetching ICD data: {e}")

@app.get("/chapters/{release_id}")
async def get_chapters(release_id: str = "2019-04") -> Dict[str, Any]:
    """
    Fetch all chapters from ICD-11 for a specific release ID.
    Caches the external API response in Redis.
    """
    endpoint = f"release/11/{release_id}/mms"
    cache_key = f"icd_chapters:{endpoint}"
    
    # Attempt to fetch from cache
    cached = redis_client.get(cache_key)
    if cached:
        return json.loads(cached)
    
    data = await fetch_icd_data(endpoint)
    # Cache the result (e.g., 10 minutes)
    redis_client.set(cache_key, json.dumps(data), ex=600)
    
    # Return a formatted response
    return {
        "releaseId": data.get("releaseId"),
        "title": data.get("title"),
        "chapters": data.get("child", [])
    }

@app.get("/icd/data")
async def get_icd_data(url: str, background_tasks: BackgroundTasks) -> Dict[str, Any]:
    """
    Endpoint that accepts any ICD API URL and returns its data using Redis cache.
    Example: /icd/data?url=https://id.who.int/icd/release/11/2019-04/mms
    """
    cache_key = f"icd_data:{url}"
    cached_data = redis_client.get(cache_key)
    if cached_data:
        return json.loads(cached_data)
    
    token = await get_valid_token()
    headers = {
        "Authorization": f"Bearer {token}",
        "Accept": "application/json",
        "Accept-Language": "en",
        "API-Version": "v2",
    }
    
    try:
        response = requests.get(url, headers=headers)
        response.raise_for_status()
        data = response.json()
        # Cache the response for 10 minutes
        redis_client.set(cache_key, json.dumps(data), ex=100000)
        return data
    except requests.exceptions.RequestException as e:
        raise HTTPException(status_code=500, detail=f"Error fetching ICD data: {e}")

# Start the token refresh task when the app starts
@app.on_event("startup")
async def startup_event():
    asyncio.create_task(refresh_token_periodically())

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
