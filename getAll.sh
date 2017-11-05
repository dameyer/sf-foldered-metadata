#!/bin/bash
# Marley Paige Meyer
# reqd files: 
#   getAll.sh: this file
#   get-folders.xml
#   build-start-tmplt.txt
# add to build.properties
# jar.location = ../ant-salesforce-40.jar
# path to force.com migration jar

which=$1 #parameter passed in Report,EmailTemplate,Dashboard,Document
lcWhich=( $(echo $1 | awk '{print tolower($1)}'))

apiVersion=40.0
tmpPkgXml=tmp-package.xml
buildFile=get-$which.xml
srcPath=src
mkdir -p $srcPath
cat build-start-tmplt.txt > $buildFile


#get all the which folders
folders=( $(ant -buildfile get-folders.xml list${which}Folders | grep FileName: | sed 's/\[sf\:listMetadata\] FileName\://' | sed 's/reports\///' | sed 's/email\///'| sed 's/dashboards\///'| sed 's/documents\///' ))

read -d '' br << EOBR
<sf:bulkRetrieve  username="\${sf.username}" 
                  password="\${sf.password}" 
                  serverurl="\${sf.serverurl}" 
                  metadataType="$which" 
                  containingFolder=
EOBR

#add folders to bulk retrieve target in which build file
for reportFolderName in ${folders[@]}; do
    echo $br"\""$reportFolderName"\" retrieveTarget=\"/$srcPath\"/>" >> $buildFile
    echo $gm >> $buildFile
done

echo "</target></project>" >> $buildFile

#retrieve all things
ant -buildfile $buildFile retrieveType


#Build Package.xml
read -d '' stPkg << STPKG
<?xml version="1.0" encoding="UTF-8"?>
<Package xmlns="http://soap.sforce.com/2006/04/metadata">
    <types>
STPKG
echo $stPkg > $srcPath/$tmpPkgXml

currentDir=`pwd`
echo $currentDir
# list all the files, parse and add to package.xml
for entry in `find $srcPath/. -name "*" -print`; do
    arr=(${entry//\// })
     if [ ${#arr[@]} == 5 ]; then
       report=${arr[4]}
       #report=`echo $report | sed 's/.report//'` 
       report=`echo $report | sed "s/.\$lcWhich//"`
       echo "<members>${arr[3]}/$report</members>" >> $srcPath/$tmpPkgXml
     fi
done

#finish writing package.xml
read -d '' eoPkg << EOPKG
        <name>$which</name>
    </types>
    <version>$apiVersion</version>
</Package>

EOPKG

echo $eoPkg >> $srcPath/$tmpPkgXml
mv $srcPath/$tmpPkgXml $srcPath/package.xml

