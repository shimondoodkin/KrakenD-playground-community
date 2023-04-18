# usage:

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

notice revoker has listening port. it is go rpc server.

run krakend first

docker run --rm -it -p "8082:8080" -p "8034:1234" --add-host host.docker.internal:host-gateway -v `cwd`/krakend.json:/etc/krakend/krakend.json devopsfaith/krakend

second run jwt revoker.

docker run --rm -it -p "8083:8080" --add-host host.docker.internal:host-gateway doodkin/jwt-revoker ./jwt-revoker -key jti -port 8080 -server host.docker.internal:8034


to revoke a token the client should request the url "/v1/jwt-revoke" with a token. and it will revoke itself
