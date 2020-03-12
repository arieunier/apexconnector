#!/bin/bash

SAVEIFS=$IFS
IFS=$(echo -en "\n\b")
# set me
if [ $# -ne 1 ]
then
    echo "Usage : deploy.sh APPLICATION_NAME "
    exit 1
fi

APPLICATION_NAME=$1

echo "######### Creating the app"
heroku apps:create $APPLICATION_NAME --region eu --buildpack heroku/python

echo "######### Adding Librato"
heroku addons:create librato --app $APPLICATION_NAME

echo "######### Adding Timber.io addon"
heroku addons:create timber-logging --app $APPLICATION_NAME

echo "######### adding other environment variables"

heroku config:set LOG_LEVEL='DEBUG' --app $APPLICATION_NAME
heroku config:set APPNAME=$APPLICATION_NAME --app $APPLICATION_NAME

echo "######### Pushing sources"
heroku git:remote -a $APPLICATION_NAME
git push heroku master


