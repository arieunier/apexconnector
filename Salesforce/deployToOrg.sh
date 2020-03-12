#!/bin/bash


SAVEIFS=$IFS
IFS=$(echo -en "\n\b")
# set me
if [ $# -ne 1 ]
then
    echo "Usage : deployToOrg.sh DevelopperHubAlias"
    exit 1
fi

DEVHUBALIAS=$1

echo "Creating Meta Data api Package"
rm -rf mdapi_output_dir
mkdir mdapi_output_dir
sfdx force:source:convert -d mdapi_output_dir/ --packagename JrAuLouvre
read -p "------------- Finished, type enter to continue " 

echo "Sending Metadata Api Package to the $DEVHUBALIAS Organisation"
sfdx force:mdapi:deploy -d mdapi_output_dir  -u $DEVHUBALIAS -w 1
read -p "------------- Finished, type enter to continue " 

echo "Updating user permissions" 
for i in `ls force-app/main/default/permissionsets/`
do
    echo 'Treating Permission file : '$i
    permissionName=`echo $i | cut -d'.' -f1`
    echo permissionName=$permissionName
    sfdx force:user:permset:assign -n $permissionName -u $DEVHUBALIAS
done