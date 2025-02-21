import requests

token_endpoint = 'https://icdaccessmanagement.who.int/connect/token'
client_id = '0042c20c-c5ca-4ed2-b31f-181520561945_60ef037c-d224-44ff-b6a2-c11bf3733af5'
client_secret = '74D7sQeJBui1srTq2E4F6YRx0I509gDZaRh0j9QTAwU='
scope = 'icdapi_access'
grant_type = 'client_credentials'


# get the OAUTH2 token

# set data to post
payload = {'client_id': client_id, 
	   	   'client_secret': client_secret, 
           'scope': scope, 
           'grant_type': grant_type}

# make request
r = requests.post(token_endpoint, data=payload, verify=False).json()
token = r['access_token']


# access ICD API

uri = 'https://id.who.int/icd/entity'

# HTTP header fields to set
headers = {'Authorization':  'Bearer '+token, 
           'Accept': 'application/json', 
           'Accept-Language': 'en',
	   'API-Version': 'v2'}
           
# make request
r = requests.get(uri, headers=headers, verify=False)

# print the result
print (r.text)