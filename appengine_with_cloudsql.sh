#!/usr/bin/env bash

echo "Enter a project name:"
read COCOON_PROJECT_ID

echo "Enter billing account id to link with the new project:"
read COCOON_BILLING_ACCOUNT_ID

# create sample rails app
rails new appengine_example
cd appengine_example

echo $(pwd)

# scaffold a sample resource
bundle exec rails generate scaffold Cat name:string age:integer

# update route and index page 
cp $COCOON_HOME/rails_templates/template_index.html.erb ./app/views/welcome/index.html.erb
cp $COCOON_HOME/rails_templates/template_cats_route.rb ./config/routes.rb

# fix bundler
bundle lock --add-platform x86_64-linux

# add dependencies
bundle add mysql2
bundle add appengine

# add deployment config for app engine
sed "s/<secret_key>/$(bundle exec rails secret)/g" $COCOON_HOME/rails_templates/template_app.yaml > app.yaml

# authorise gcloud
gcloud auth login

# create a gcp project
COCOON_PROJECT_ID=$COCOON_PROJECT_ID COCOON_BILLING_ACCOUNT_ID=$COCOON_BILLING_ACCOUNT_ID ruby $COCOON_HOME/clients/deploy_appengine.rb
gcloud config set project $COCOON_PROJECT_ID

echo "Provide details for cloudSQL:"
echo "DB Instance name:"
read COCOON_DB_INSTANCE_NAME

echo "DB name:"
read COCOON_DB_NAME

echo "Instance Region:"
read COCOON_REGION

echo "Root user password:"
read COCOON_DB_ROOT_PASSWORD

# setup cloudsql instance 
gcloud sql instances create $COCOON_DB_INSTANCE_NAME  --tier=db-f1-micro  --region=$COCOON_REGION
gcloud sql databases create $COCOON_DB_NAME  --instance=$COCOON_DB_INSTANCE_NAME 
gcloud sql users set-password root --host=% --instance $COCOON_DB_INSTANCE_NAME --password $COCOON_DB_ROOT_PASSWORD 

USER_NAME="s/<YOUR_MYSQL_USERNAME>/root/g"
PASSWORD="s/<YOUR_MYSQL_PASSWORD>/$COCOON_DB_ROOT_PASSWORD/g"
DATABASE_NAME="s/<YOUR_DATABASE_NAME>/$COCOON_DB_NAME/g"
CONNECTION_STRING="s/<YOUR_INSTANCE_CONNECTION_NAME>/$COCOON_PROJECT_ID:$COCOON_REGION:$COCOON_DB_INSTANCE_NAME/g"
sed "$USER_NAME;$PASSWORD;$CONNECTION_STRING;$DATABASE_NAME" $COCOON_HOME/rails_templates/template_database.yml > ./config/database.yml

printf "\nbeta_settings:\n  cloud_sql_instances: $COCOON_PROJECT_ID:$COCOON_REGION:$COCOON_DB_INSTANCE_NAME" >> app.yaml

# precompile assets
bundle exec bin/rails assets:precompile

#run db migration
bundle exec rake appengine:exec -- bundle exec rake db:migrate

# deploy the app
gcloud app create
gcloud app deploy
gcloud app browse

