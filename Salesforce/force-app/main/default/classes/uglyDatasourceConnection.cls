global class uglyDatasourceConnection extends DataSource.Connection 
    {
        private DataSource.ConnectionParams connectionInfo;
        private String TABLE_FUNCTION = 'tables?output=json';
        private String OBJECT_FUNCTION = 'getObjects?output=json&describe=True&name=';


        global uglyDatasourceConnection(DataSource.ConnectionParams connectionParams) 
        {
            System.debug('Connection Params created');
            System.debug(connectionParams);
            this.connectionInfo = connectionParams;

        }

        private HttpResponse callAPI(String endpointURL)
        {
            Http httpProtocolTable = new Http();
            HttpRequest requestTable = new HttpRequest();
            requestTable.setEndpoint(endpointURL);
            requestTable.setMethod('GET');
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
            String jsonData = callApi(connectionInfo.endpoint + TABLE_FUNCTION).getBody();
            Map<String, Object> m = (Map<String, Object>) JSON.deserializeUntyped(jsonData);
            List<Object> data = (List<Object>) m.get('data');
            
            for (Object o : data) {
                Map<String, Object> p = (Map<String, Object>) o;
                String table_name = (String)p.get('table_name');
                String table_schema = (String)p.get('table_schema');
                
                List<DataSource.Column> columns = new List<DataSource.Column>();

                // now calls the getObject function
                String jsonDataObject = callApi(connectionInfo.endpoint + OBJECT_FUNCTION + table_name).getBody();
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

}