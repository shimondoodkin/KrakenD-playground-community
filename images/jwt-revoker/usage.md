# usage:
how revokation works:

krakend has some built-in bloom filter that has an RPC (remote pricedure call, it allows remote function execution).
using that rpc call it is possible to add to the bloom filter, from the decoded token json, a field for example "jti".
adding a jti value from a token to bloom filter will block all tokens with that field value for bloom filter ("auth/revoker") TTL seconds.

example token data decoded:

jti is field below:

```
{
  "exp": 1681787475,
  "iat": 1681787175,
  "auth_time": 1681787174,
  "jti": "afc393ea-e3b0-4e9e-8777-1ee4e8d0b3eb",
  "iss": "http://localhost:8080/realms/keycloak-demo",
  "aud": "account",
  "sub": "c264b963-3510-4d6a-9280-5b2840c6f9ab",
  "typ": "Bearer",
  "azp": "app-vue",
  "nonce": "21044efa-b61b-4b1a-a8a3-846d9b6b7715",
  "session_state": "7947acb6-be6e-4e00-b5b6-ed882ac480ac",
  "acr": "1",
  "allowed-origins": [
    "http://localhost:8081"
  ],
  "realm_access": {
    "roles": [
      "default-roles-keycloak-demo",
      "offline_access",
      "uma_authorization"
    ]
  },
  "resource_access": {
    "account": {
      "roles": [
        "manage-account",
        "manage-account-links",
        "view-profile"
      ]
    }
  },
  "scope": "openid email profile",
  "sid": "7947acb6-be6e-4e00-b5b6-ed882ac480ac",
  "email_verified": false,
  "preferred_username": "user",
  "given_name": "",
  "family_name": ""
}
```

example output:

```
for example requesting: 

http://localhost:8083/add/?jti=93ad16ee-2cdf-47ff-a10a-780b8d5a6bdd
```
example output
```

docker run --rm -it -p "8083:8080" --add-host host.docker.internal:host-gateway doodkin/jwt-revoker ./jwt-revoker -key jti -port 8080 -server host.docker.internal:8034
2023/04/18 00:58:21 adding [jti] jti-afc393ea-e3b0-4e9e-8777-1ee4e8d0b3eb
2023/04/18 01:07:07 adding [jti] jti-37bb3c7f-e8f9-43df-8807-d6f7a535874d
2023/04/18 01:10:41 adding [jti] jti-48316305-2304-49b0-a6f9-06a921e142f8

```

configure krakend


```
{
  "$schema": "https://www.krakend.io/schema/v3.json",
  "version": 3,
  "name": "KrakenD - API Gateway",
  "timeout": "3000ms",
  "cache_ttl": "300s",
  "endpoints": [


    {
      "endpoint": "/v1/jwt-revoke",
      "method": "GET",
      "output_encoding": "string",
      "cache_ttl": "1s",
      "input_headers": [
        "x-jti"
      ],
      "backend": [
        {
          "url_pattern": "/addheader",
          "encoding": "string",
          "sd": "static",
          "method": "GET",
          "host": [
            "http://host.docker.internal:8083"
          ],
          "disable_host_sanitize": false
        }
      ],
      "extra_config": {
        "auth/validator": {

          "propagate_claims": [
                ["jti", "x-jti"]
          ],
          "alg": "RS256",
          "jwk_url": "http://host.docker.internal:8080/realms/keycloak-demo/protocol/openid-connect/certs",
          "disable_jwk_security": true,
          "issuer": "http://localhost:8080/realms/keycloak-demo",
          "roles": [
           
          ],
          "operation_debug": true
        }
      }

    }

  ],
  
  
  
  
  
  
  
  
  "output_encoding": "json",
  "extra_config": {
    "security/cors": {
      "allow_origins": [
        "http://localhost:8081"
      ],
      "expose_headers": [
        "Content-Length","Authorization"
      ],
      "max_age": "12h",
      "allow_methods": [
        "GET",
        "HEAD",
        "POST"
      ],
      "allow_headers": [
        "Authorization"
      ],
      "debug":true
    },

    "auth/revoker": {
      "N": 10000000,
      "P": 0.0000001,
      "hash_name": "optimal",
      "TTL": 1500,
      "port": 1234,
      "token_keys": ["jti"]
    }
  }
}
```

Notice krakend "auth/revoker" has an additional listening port. it is go rpc server. the revoker client connects to it to ask to block a jti value


Run krakend first

docker run --rm -it -p "8082:8080" -p "8034:1234" --add-host host.docker.internal:host-gateway -v `cwd`/krakend.json:/etc/krakend/krakend.json devopsfaith/krakend

Second run jwt revoker.

docker run --rm -it -p "8083:8080" --add-host host.docker.internal:host-gateway doodkin/jwt-revoker ./jwt-revoker -key jti -port 8080 -server host.docker.internal:8034


To revoke a token the client should request the url "/v1/jwt-revoke" with a token. and it will revoke itself.

because I have not found yet how to call a url after session finishing in key clock i just call it right before log out.

There are problems: if krakend restarts and revoker survives, krakend forgets all revoked tokens, the revoker does not remind krakend about the revoked tokens.
also seems it does not reconnect if restarting the krakend.
