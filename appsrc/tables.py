
from flask import Flask, request, redirect, url_for, render_template
import os, logging, psycopg2 
from datetime import datetime 
import ujson
import uuid
from libs import postgres , utils , logs
from appsrc import app, logger



@app.route('/tables', methods=['GET'])
def tables():
    try :
        cookie , cookie_exists=  utils.getCookie()
        logger.debug(utils.get_debug_all(request))
        data_dict  = postgres.__getTables()
        data = ujson.dumps(data_dict)
        return utils.returnResponse(data, 200, cookie, cookie_exists)
        
    except Exception as e:
        import traceback
        traceback.print_exc()
        cookie , cookie_exists=  utils.getCookie()
        return utils.returnResponse("An error occured, check logs for more information", 200, cookie, cookie_exists)


@app.route('/getObjects', methods=['GET'])
def getObjects():
    try: 
        cookie , cookie_exists = utils.getCookie()
        # output type
        # logs all attributes received
        logger.debug(utils.get_debug_all(request))
        # gets object name
        describe = False
        if ('describe' in request.args):
            describe = True
        
        object_name=''
        if ('name' in request.args):
            object_name = request.args['name']
        else:
            return "Error, must specify a object name with ?name=xxx", 404
            
        data_dict = None
        data_dict  = postgres.__getObjectsDescribe(object_name, describe) 
        data = ujson.dumps(data_dict)#{'columns':data_dict['columns']})
        return utils.returnResponse(data, 200, cookie, cookie_exists)

    except Exception as e:
        import traceback
        traceback.print_exc()
        cookie =  utils.getCookie()
        return utils.returnResponse("An error occured, check logs for more information", 200, cookie, cookie_exists)
