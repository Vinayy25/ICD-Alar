import os
import requests
from fastapi import FastAPI, HTTPException
from typing import List, Dict, Any
from dotenv import load_dotenv
load_dotenv()

client_id = os.getenv("ICD_CLIENT_ID")
client_secret = os.getenv("ICD_CLIENT_SECRET")

    
app = FastAPI()

ICD_BASE_URL = "https://id.who.int/icd"
def fetch_token():
    scope = 'icdapi_access'
    grant_type = 'client_credentials'
    token_endpoint = "https://icdaccessmanagement.who.int/connect/token"

    # set data to post
    payload = {'client_id': client_id, 
            'client_secret': client_secret, 
            'scope': scope, 
            'grant_type': grant_type}
            
    # make request
    r = requests.post(token_endpoint, data=payload, verify=False).json()
    print(r)
    token = r['access_token']

    return token

CURRENT_TOKEN = fetch_token()

def fetch_icd_data(endpoint: str) -> Dict[str, Any]:
    """
    Generic function to fetch data from the ICD API using the given endpoint.
    """
    BEARER_TOKEN = CURRENT_TOKEN
    
    headers = {
        "Authorization": f"Bearer {BEARER_TOKEN}",
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
    Default release_id is 2019-04.
    Returns the complete chapter information including titles and IDs.
    """
    endpoint = f"release/11/{release_id}/mms"
    data = fetch_icd_data(endpoint)
    
    # The response includes chapter information in the 'child' field
    return {
        "releaseId": data.get("releaseId"),
        "title": data.get("title"),
        "chapters": data.get("child", [])
    }

@app.get("/icd/data")
async def get_icd_data(url: str) -> Dict[str, Any]:
    """
    Simple endpoint that accepts any ICD API URL and returns its data.
    Example: /icd/data?url=https://id.who.int/icd/release/11/2019-04/mms
    """
    token = CURRENT_TOKEN
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
        raise HTTPException(status_code=500, detail=f"Error fetching ICD data: {e}")

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
