import os
import json
import requests
import redis
import asyncio
from datetime import datetime, timedelta
from fastapi import FastAPI, HTTPException, BackgroundTasks
from typing import List, Dict, Any
from dotenv import load_dotenv
from fastapi.middleware.cors import CORSMiddleware

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
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # ["http://localhost:3000", "https://yourdomain.com"]
    allow_credentials=True,
    allow_methods=["GET", "POST", "PUT", "DELETE", "OPTIONS"],
    allow_headers=["*"],
)
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

@app.get("/search")
async def search_icd(
    q: str,
    release_id: str = "2025-01",
    subtreeFilterUsesFoundationDescendants: bool = False,
    includeKeywordResult: bool = True,
    useFlexisearch: bool = False,
    flatResults: bool = True,
    highlightingEnabled: bool = True,
    medicalCodingMode: bool = True
) -> Dict[str, Any]:
    """
    Search the ICD-11 database with a query string.
    This endpoint replicates the ICD API search functionality.
    
    Args:
        q: Query string to search for
        release_id: ICD release ID (default: 2025-01)
        Other parameters match the official ICD API search parameters
    """
    # Create cache key based on all parameters
    params = {
        "q": q,
        "subtreeFilterUsesFoundationDescendants": str(subtreeFilterUsesFoundationDescendants).lower(),
        "includeKeywordResult": str(includeKeywordResult).lower(),
        "useFlexisearch": str(useFlexisearch).lower(),
        "flatResults": str(flatResults).lower(),
        "highlightingEnabled": str(highlightingEnabled).lower(),
        "medicalCodingMode": str(medicalCodingMode).lower()
    }
    
    # Create a deterministic cache key from parameters
    param_str = "&".join([f"{k}={v}" for k, v in sorted(params.items())])
    cache_key = f"icd_search:{release_id}:{param_str}"
    
    # Try to get from cache
    cached_data = redis_client.get(cache_key)
    if cached_data:
        return json.loads(cached_data)
    
    # Prepare the search request
    token = await get_valid_token()
    headers = {
        "Authorization": f"Bearer {token}",
        "Accept": "application/json",
        "Accept-Language": "en",
        "API-Version": "v2",
    }
    
    # Build search URL
    search_url = f"{ICD_BASE_URL}/release/11/{release_id}/mms/search"
    
    try:
        response = requests.get(search_url, headers=headers, params=params)
        response.raise_for_status()
        data = response.json()
        
        # Cache results for 1 hour (can adjust as needed)
        redis_client.set(cache_key, json.dumps(data), ex=3600)
        
        return data
    except requests.exceptions.RequestException as e:
        error_msg = f"Error searching ICD data: {str(e)}"
        if hasattr(e.response, 'text'):
            error_msg += f" Response: {e.response.text}"
        raise HTTPException(status_code=500, detail=error_msg)

# Start the token refresh task when the app starts
@app.on_event("startup")
async def startup_event():
    asyncio.create_task(refresh_token_periodically())

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
