import os
import json
import requests
import redis
import asyncio
import logging
from datetime import datetime, timedelta
from fastapi import FastAPI, HTTPException, BackgroundTasks
from typing import List, Dict, Any, Set
from dotenv import load_dotenv
from fastapi.middleware.cors import CORSMiddleware

# Set up logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger("icd_api")

load_dotenv()

client_id = os.getenv("ICD_CLIENT_ID")
client_secret = os.getenv("ICD_CLIENT_SECRET")

app = FastAPI()
ICD_BASE_URL = "https://id.who.int/icd"
ICD_ROOT_URL = "https://id.who.int/icd/release/11/2025-01/mms"
CACHE_TTL = 60 * 60 * 12  # 12 hours in seconds
CACHE_REFRESH_INTERVAL = timedelta(hours=12)

# Initialize the Redis client
redis_client = redis.Redis(host='localhost', port=6379, db=0, decode_responses=True)

# Add these global variables
CURRENT_TOKEN = None
LAST_TOKEN_REFRESH = None
TOKEN_REFRESH_INTERVAL = timedelta(minutes=15)
CACHE_LOCK = asyncio.Lock()
PRECACHE_IN_PROGRESS = False

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
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
            logger.info(f"Token refreshed at: {LAST_TOKEN_REFRESH}")
            await asyncio.sleep(TOKEN_REFRESH_INTERVAL.total_seconds())
        except Exception as e:
            logger.error(f"Error refreshing token: {e}")
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
    token = r['access_token']
    return token

async def fetch_icd_data(url: str) -> Dict[str, Any]:
    """
    Generic function to fetch data from the ICD API using the given URL.
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
        response = requests.get(url, headers=headers)
        response.raise_for_status()
        return response.json()
    except requests.exceptions.RequestException as e:
        logger.error(f"Error fetching ICD data from {url}: {e}")
        raise HTTPException(status_code=500, detail=f"Error fetching ICD data: {e}")

async def precache_icd_data(url: str, depth: int = 2, processed_urls: Set[str] = None) -> None:
    """
    Recursively fetch and cache ICD data up to the specified depth.
    This creates a tree of cached data starting from the root URL.
    
    Args:
        url: The URL to fetch and cache
        depth: How many levels deep to fetch children (0 = just this URL)
        processed_urls: Set of URLs that have already been processed
    """
    global PRECACHE_IN_PROGRESS
    
    if processed_urls is None:
        processed_urls = set()
    
    # Skip if we've already processed this URL
    if url in processed_urls:
        return
    
    processed_urls.add(url)
    
    # Check if it's already in cache
    cache_key = f"icd_data:{url}"
    cached_data = redis_client.get(cache_key)
    
    try:
        # Fetch and cache if not in cache already
        if not cached_data:
            logger.info(f"Pre-caching URL: {url}")
            data = await fetch_icd_data(url)
            redis_client.set(cache_key, json.dumps(data), ex=CACHE_TTL)
            logger.info(f"Cached {url} (expires in {CACHE_TTL} seconds)")
        else:
            data = json.loads(cached_data)
            logger.debug(f"URL already cached: {url}")
        
        # Stop recursion if we've reached the max depth
        if depth <= 0:
            return
        
        # Process child URLs recursively
        child_urls = []
        if 'child' in data and isinstance(data['child'], list):
            child_urls.extend(data['child'])
        
        for child_url in child_urls:
            await precache_icd_data(child_url, depth - 1, processed_urls)
    
    except Exception as e:
        logger.error(f"Error pre-caching {url}: {e}")

async def refresh_cache_periodically():
    """Background task to refresh the cache every 12 hours"""
    global PRECACHE_IN_PROGRESS
    
    while True:
        try:
            if not PRECACHE_IN_PROGRESS:
                PRECACHE_IN_PROGRESS = True
                logger.info("Starting scheduled cache refresh")
                
                # Clear cache stats
                processed_count = 0
                start_time = datetime.now()
                
                # Start pre-caching from root
                await precache_icd_data(ICD_ROOT_URL, depth=2)
                
                end_time = datetime.now()
                logger.info(f"Cache refresh completed in {end_time - start_time}")
                PRECACHE_IN_PROGRESS = False
            
            # Wait for the next refresh interval
            await asyncio.sleep(CACHE_REFRESH_INTERVAL.total_seconds())
        
        except Exception as e:
            logger.error(f"Error refreshing cache: {e}")
            PRECACHE_IN_PROGRESS = False
            await asyncio.sleep(300)  # Wait 5 minutes before retrying on error

@app.get("/chapters/{release_id}")
async def get_chapters(release_id: str = "2025-01") -> Dict[str, Any]:
    """
    Fetch all chapters from ICD-11 for a specific release ID.
    Uses pre-cached data when available.
    """
    url = f"{ICD_BASE_URL}/release/11/{release_id}/mms"
    cache_key = f"icd_data:{url}"
    
    # Attempt to fetch from cache
    cached = redis_client.get(cache_key)
    if cached:
        data = json.loads(cached)
    else:
        # If not in cache, fetch and cache it
        data = await fetch_icd_data(url)
        redis_client.set(cache_key, json.dumps(data), ex=CACHE_TTL)
        
        # Trigger background pre-caching of children
        background_tasks = BackgroundTasks()
        background_tasks.add_task(precache_icd_data, url, 2)
    
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
    Example: /icd/data?url=https://id.who.int/icd/release/11/2025-01/mms
    """
    cache_key = f"icd_data:{url}"
    cached_data = redis_client.get(cache_key)
    
    if cached_data:
        return json.loads(cached_data)
    
    # If not in cache, fetch and cache it
    data = await fetch_icd_data(url)
    redis_client.set(cache_key, json.dumps(data), ex=CACHE_TTL)
    
    # Pre-cache children in the background for a smoother user experience
    background_tasks.add_task(precache_icd_data, url, 1)  # Only one level deep for ad-hoc requests
    
    return data

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
        logger.debug(f"Search cache hit: {q}")
        return json.loads(cached_data)
    
    logger.info(f"Search cache miss: {q}")
    
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
        
        # Cache search results for 1 hour
        # (Search results are more dynamic than the hierarchical structure)
        redis_client.set(cache_key, json.dumps(data), ex=3600)
        
        # Pre-cache entities in search results
        if 'destinationEntities' in data:
            for entity in data['destinationEntities']:
                if 'id' in entity and isinstance(entity['id'], str):
                    entity_url = entity['id']
                    entity_cache_key = f"icd_data:{entity_url}"
                    
                    # Only store minimal entity data to save Redis memory
                    minimal_entity = {
                        "id": entity.get("id"),
                        "title": entity.get("title"),
                        "code": entity.get("code"),
                        "browserUrl": entity.get("browserUrl")
                    }
                    
                    # Cache for 12 hours
                    if not redis_client.exists(entity_cache_key):
                        redis_client.set(entity_cache_key, json.dumps(minimal_entity), ex=CACHE_TTL)
        
        return data
    except requests.exceptions.RequestException as e:
        error_msg = f"Error searching ICD data: {str(e)}"
        if hasattr(e, 'response') and e.response and hasattr(e.response, 'text'):
            error_msg += f" Response: {e.response.text}"
        logger.error(error_msg)
        raise HTTPException(status_code=500, detail=error_msg)

@app.get("/cache/stats")
async def get_cache_stats():
    """Get statistics about the cache"""
    info = redis_client.info()
    keys_info = {}
    
    # Count keys with different prefixes
    for prefix in ["icd_data:", "icd_search:", "icd_chapters:"]:
        keys_info[prefix] = len(redis_client.keys(f"{prefix}*"))
    
    # Get memory info
    memory_info = {
        "used_memory_human": info.get("used_memory_human", "unknown"),
        "used_memory_peak_human": info.get("used_memory_peak_human", "unknown")
    }
    
    return {
        "keys": keys_info,
        "total_keys": len(redis_client.keys("*")),
        "memory": memory_info,
        "precache_in_progress": PRECACHE_IN_PROGRESS,
    }

@app.post("/cache/refresh")
async def trigger_cache_refresh(background_tasks: BackgroundTasks):
    """Manually trigger a cache refresh"""
    global PRECACHE_IN_PROGRESS
    
    if PRECACHE_IN_PROGRESS:
        return {"status": "already_running", "message": "Cache refresh is already in progress"}
    
    background_tasks.add_task(precache_icd_data, ICD_ROOT_URL, 2)
    return {"status": "started", "message": "Cache refresh started"}

# Start the token refresh and cache refresh tasks when the app starts
@app.on_event("startup")
async def startup_event():
    asyncio.create_task(refresh_token_periodically())
    asyncio.create_task(refresh_cache_periodically())
    logger.info("ICD API server started")

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
