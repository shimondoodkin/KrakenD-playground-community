# to push an image:
#
# register to docker hub
# go to https://hub.docker.com/ > in account (user avatar on top) > account settings > security > generate a token with (Read, Write, Delete) permissions
# run the commands given after token creation
# then you can do docker push
# note: the below should be your-account/image-name

docker build -t doodkin/jwt-revoker .
# docker push doodkin/jwt-revoker
