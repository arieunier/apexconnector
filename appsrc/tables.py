
from flask import Flask, request, redirect, url_for, render_template
import os, logging, psycopg2 
from datetime import datetime 
import ujson, uuid, base64
from libs import postgres , utils , logs
from appsrc import app, logger


def checkAuthorization(request):
    if ("Authorization" not in request.headers):
        logger.error("Authorization code is not in headers")
        return  True
    else:
        authorizationCode = request.headers['Authorization']
        #base decode
        authorizationCodeB64 = authorizationCode.split(" ")[1]
        logger.info("Authorization Code in B64={}".format(authorizationCodeB64))
        logger.info("Authorization Code decoded={}".format(base64.b64decode(authorizationCodeB64)))
        return  True


@app.route('/tables', methods=['GET'])
def tables():
    try :
        cookie , cookie_exists=  utils.getCookie()
        logger.debug(utils.get_debug_all(request))
        if (not checkAuthorization(request)):
            return utils.returnResponse("Unauthorized access", 401, cookie, cookie_exists)
        #Postgres part    
        data_dict  = postgres.__getTables()
        data = ujson.dumps(data_dict)
        return utils.returnResponse(data, 200, cookie, cookie_exists)
        
    except Exception as e:
        import traceback
        traceback.print_exc()
        cookie , cookie_exists=  utils.getCookie()
        return utils.returnResponse("The server encountered an error while processing your request", 500, cookie, cookie_exists)


@app.route('/getObjects', methods=['GET'])
def getObjects():
    try: 
        cookie , cookie_exists = utils.getCookie()
        logger.debug(utils.get_debug_all(request))
        if (not checkAuthorization(request)):
            return utils.returnResponse("Unauthorized access", 401, cookie, cookie_exists)
        
        # gets object name
        describe = False
        if ('describe' in request.args):
            describe = True
        
        object_name=''
        if ('name' in request.args):
            object_name = request.args['name']
        else:
            return utils.returnResponse("Error, must specify a object name with ?name=xxx", 403, cookie, cookie_exists)
            
        data_dict = None
        data_dict  = postgres.__getObjectsDescribe(object_name, describe) 
        data = ujson.dumps(data_dict)#{'columns':data_dict['columns']})
        return utils.returnResponse(data, 200, cookie, cookie_exists)

    except Exception as e:
        import traceback
        traceback.print_exc()
        cookie =  utils.getCookie()
        return utils.returnResponse("The server encountered an error while processing your request", 500, cookie, cookie_exists)
