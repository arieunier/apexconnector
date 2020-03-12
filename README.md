Creates a REST API exposing the Database content. 
This REST API  can be consumed using APEX Connector in Salesforce

Steps
1- Clone the git
2- Launch the deploy.sh giving a name (ex: yournameapexconnector) to create the heroku app
3- Go into the Salesforce folder and deploy the source to your org
4- open the org and go to remote site to update the default herokuapp  url to the one you create
5- open the external data source and do the same
When clicking on sync, any table in Postgres will be available as an external object.

Note:
only the first part (sync method) is done, query/search/.. will be done at a later stage


Deploy it here
[![Deploy](https://www.herokucdn.com/deploy/button.svg)](https://heroku.com/deploy?template=https://arieunier@github.com/arieunier/apexconnector.git)
