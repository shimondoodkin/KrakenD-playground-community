SET CURRENT_FOLDER_NAME=%~dp0
SET CURRENT_FOLDER_NAME=%CURRENT_FOLDER_NAME:~0,-1%

:: basic non-scalable revoker

docker run --rm -it -p "8083:8080" --add-host host.docker.internal:host-gateway doodkin/jwt-revoker ./jwt-revoker -key jti -port 8080 -server host.docker.internal:8034
