#!/usr/bin/env bash

if [ $2 == "appengine" ]
then
  $COCOON_HOME/appengine.sh
else 
  $COCOON_HOME/appengine_with_cloudsql.sh
fi  
