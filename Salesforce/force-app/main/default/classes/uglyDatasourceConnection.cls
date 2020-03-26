global class uglyDatasourceConnection extends DataSource.Connection 
    {
        private DataSource.ConnectionParams connectionInfo;
        private String TABLE_FUNCTION = 'tables?output=json';
        private String OBJECT_FUNCTION = 'getObjects?output=json&describe=True&name=';
        private String QUERY_FUNCTION = 'getObjects?output=json&name=';

        global uglyDatasourceConnection(DataSource.ConnectionParams connectionParams) 
        {
            System.debug('Connection Params created');
            System.debug(connectionParams);
            this.connectionInfo = connectionParams;

        }

        private HttpResponse callAPI(String endpointURL, String username, String password)
        {
            Http httpProtocolTable = new Http();
            HttpRequest requestTable = new HttpRequest();
            requestTable.setEndpoint(endpointURL);
            requestTable.setMethod('GET');

            Blob headerValue = Blob.valueOf(username + ':' + password);
            String authorizationHeader = 'BASIC ' + EncodingUtil.base64Encode(headerValue);
            requestTable.setHeader('Authorization', authorizationHeader);


            HttpResponse response = httpProtocolTable.send(requestTable);
            System.debug(response.getBody());
            return response;
        }
        
        override global List<DataSource.Table> sync() 
        {
            System.debug('Sync Function Called');
            System.debug(connectionInfo.endpoint);
            List<DataSource.Table> tables = new List<DataSource.Table>();
            // connect to the http endpoint
            String jsonData = callApi(connectionInfo.endpoint + TABLE_FUNCTION,
                    connectionInfo.username,
                    connectionInfo.password).getBody();
            Map<String, Object> m = (Map<String, Object>) JSON.deserializeUntyped(jsonData);
            List<Object> data = (List<Object>) m.get('data');
            
            for (Object o : data) {
                Map<String, Object> p = (Map<String, Object>) o;
                String table_name = (String)p.get('table_name');
                String table_schema = (String)p.get('table_schema');
                
                List<DataSource.Column> columns = new List<DataSource.Column>();

                // now calls the getObject function
                String jsonDataObject = callApi(connectionInfo.endpoint + OBJECT_FUNCTION + table_name,
                        connectionInfo.username,
                        connectionInfo.password).getBody();
                Map<String, Object> obj = (Map<String, Object>) JSON.deserializeUntyped(jsonDataObject);
                List<Object> dataObj = (List<Object>) obj.get('columns');
                for (Object field : dataObj)
                {
                    columns.add(DataSource.Column.text((String)field, 255));
                }
                // Mandatory fields
                columns.add(DataSource.Column.url('DisplayUrl'));
                columns.add(DataSource.Column.text('ExternalId',255));

                tables.add(DataSource.Table.get(table_schema + '.' + table_name, 
                table_schema + '.' + table_name, 
                                                columns));
            }
			
        return tables;

        }

    /**
     *   Called to do a full text search and get results from
     *   the external system for SOSL queries and Salesforce
     *   global searches.
     *
     *   The SearchContext argument represents the query to run
     *   against a table in the external system.
     *
     *   Returns results for each table that the SearchContext
     *   requested to be searched.
     **/
    override global List<DataSource.TableResult> search(DataSource.SearchContext context) 
    {
        List<DataSource.TableResult> results = new List<DataSource.TableResult>();
        
        system.debug('entre dans search');
        system.debug('context=' + context);
        

        for (Integer i =0;i< context.tableSelections.size();i++) 
        {
            String entity = context.tableSelections[i].tableSelected;

            // Search usernames
            //String url = connectionInfo.endpoint + OBJECT_FUNCTION + table_name + context.searchPhrase;
            String url = 'https://mytableexposedinrestdemo.herokuapp.com/getObjects?output=json&describe=True&name=badge' + context.searchPhrase;
            //String url = 'https://mytableexposedinrestdemo.herokuapp.com/getObjects?output=json&describe=True&name=badge';

            system.System.debug('url'+ url);
            results.add(DataSource.TableResult.get(true, null, entity, getData(url)));
        }
        return results;
    }


    /**
     *   Helper method to parse the data.
     *   The url argument is the URL of the external system.
     *   Returns a list of rows from the external system.
     **/
    public List<Map<String, Object>> getData(String url) 
    {
        String response = callAPI(url,connectionInfo.username, connectionInfo.username).getBody();

        // Standardize response string
        if (!response.contains('"data":'))
        {
            if (response.substring(0,1).equals('{'))
            {
                response = '[' + response  + ']';
            }
            response = '{"data": ' + response + '}';
        }
        List<Map<String, Object>> rows = new List<Map<String, Object>>();

        Map<String, Object> responseBodyMap = (Map<String, Object>) JSON.deserializeUntyped(response);

        /**
         *   Checks errors.
         **/
        Map<String, Object> error = (Map<String, Object>)responseBodyMap.get('error');
        if (error!=null) {
            List<Object> errorsList =
                    (List<Object>)error.get('errors');
            Map<String, Object> errors =
                    (Map<String, Object>)errorsList[0];
            String errorMessage = (String)errors.get('message');
            throw new 
                    DataSource.OAuthTokenExpiredException(errorMessage);
        }

        List<Object> fileItems = (List<Object>)responseBodyMap.get('data');
        if (fileItems != null) {
            for (Integer i=0; i < fileItems.size(); i++) 
            {
                Map<String, Object> item = (Map<String, Object>)fileItems[i];
                rows.add(createRow(item));
            }
        } else 
        {
            rows.add(createRow(responseBodyMap));
        }
        system.debug('return rows');
        return rows;
    }

    public Map<String, Object> createRow(Map<String, Object> item)
    {
        Map<String, Object> row = new Map<String, Object>();
        for ( String key : item.keySet() ) 
        {
            system.debug('###### KEY/VALUE=> [' + key + ']/[' + item.get(key) + ']');
            if (key.equalsIgnoreCase('externalid'))
            {
                system.debug('###### Found external id');
                row.put('ExternalId', item.get(key));
            }
            else if (key.equalsIgnoreCase('displayurl'))
            {
                system.debug('###### Found displayurl');                
                row.put('DisplayUrl', item.get(key));
            }
            else
            {
				row.put(key, item.get(key));
            }
            /*
            if (key == 'guest_id') 
            {
                row.put('ExternalId', item.get(key));
            } else if (key=='badge_url') 
            {
                row.put('DisplayUrl', item.get(key));
            }
			
            row.put(key, item.get(key));
			*/
        }
        system.debug('return row'+ row);
        return row;
    }

    /**
     *   Called to query and get results from the external 
     *   system for SOQL queries, list views, and detail pages 
     *   for an external object that’s associated with the 
     *   external data source.
     *   
     *   The queryContext argument represents the query to run 
     *   against a table in the external system.
     *   
     *   Returns a list of rows as the query results.
     **/
    override global DataSource.TableResult query( DataSource.QueryContext context) 
    {
        DataSource.Filter filter = context.tableSelection.filter;
        String url;
        system.debug('entre dans query');
        system.debug(context);
        system.debug('context metadata =' + context.metadata);
        String objectName = context.metadata[0].name;
        system.debug('External Object Name = ' + objectName);
        
        if (filter != null) 
        {
            String thisColumnName = filter.columnName;
            if (thisColumnName != null &&
               (thisColumnName.equals('ExternalId') ||
                thisColumnName.equals('login')))
                url = connectionInfo.endpoint +'/' + QUERY_FUNCTION + objectName;
            else 
                url = connectionInfo.endpoint + '/' +  QUERY_FUNCTION +  objectName;
        } 
        else 
        {
            url = connectionInfo.endpoint +'/' + QUERY_FUNCTION + objectName;
        }

        /**
         * Filters, sorts, and applies limit and offset clauses.
         **/
        List<Map<String, Object>> rows = DataSource.QueryUtils.process(context, getData(url));
        return DataSource.TableResult.get(true, null, context.tableSelection.tableSelected, rows);
    }

}