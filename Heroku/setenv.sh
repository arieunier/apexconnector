APPNAME=$1

export PYTHONPATH=.:./libs/:./appsrc/
export DATABASE_URL=`heroku config:get DATABASE_URL --app $APPNAME`
