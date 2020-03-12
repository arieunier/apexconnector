from sqlalchemy import create_engine
from sqlalchemy import create_engine
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker
from datetime import datetime 
import os , ujson
import uuid
import logs, utils

DATABASE_URL = os.getenv('DATABASE_URL','')
MANUAL_ENGINE_POSTGRES = None

logger = logs.logger_init(loggername='app',
            filename="log.log",
            debugvalue=logs.LOG_LEVEL,
            flaskapp=None)

if (DATABASE_URL != ''):
    Base = declarative_base()
    MANUAL_ENGINE_POSTGRES = create_engine(DATABASE_URL, pool_size=30, max_overflow=0)
    Base.metadata.bind = MANUAL_ENGINE_POSTGRES
    dbSession_postgres = sessionmaker(bind=MANUAL_ENGINE_POSTGRES)
    session_postgres = dbSession_postgres()
    logger.info("{} - Initialization done Postgresql ".format(datetime.now()))

def __execRequestWithNoResult(strReq, attributes=None):
    if (MANUAL_ENGINE_POSTGRES != None):
        result = MANUAL_ENGINE_POSTGRES.execute(strReq, attributes)


def __execRequest(strReq, Attributes):
    if (MANUAL_ENGINE_POSTGRES != None):
        result = MANUAL_ENGINE_POSTGRES.execute(strReq, Attributes)
        return utils.__resultToDict(result)
    return {'data' : [], "columns": []}

def __getObjectsDescribe(tableName):

    data = __execRequest("select * from {} limit 1".format(tableName), {})
    logger.debug("Data Returned")
    logger.debug(data)
    return data


def __getTables():
    sqlRequest = "SELECT table_schema, table_name FROM information_schema.tables where table_schema not like '%%information_schema' and table_schema not like '%%pg_catalog'"
    data = __execRequest(sqlRequest, {})
    logger.debug("Data Returned")
    logger.debug(data)
    return data


