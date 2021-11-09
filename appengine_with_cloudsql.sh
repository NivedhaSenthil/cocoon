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
COCOON_PROJECT_NUMBER=$(gcloud projects describe $COCOON_PROJECT_ID --format='value(projectNumber)')

# enable service apis
gcloud services enable serviceusage.googleapis.com
gcloud services enable cloudbuild.googleapis.com
gcloud services enable sqladmin.googleapis.com
gcloud app create

echo "Provide details for cloudSQL:"
echo "DB Instance name:"
read COCOON_DB_INSTANCE_NAME

echo "DB name:"
read COCOON_DB_NAME

echo "Instance Region:"
read COCOON_REGION

# generate dbpassword
cat /dev/urandom | LC_ALL=C tr -dc '[:alpha:]'| fold -w 50 | head -n1 >> dbpassword

# setup cloudsql instance 
gcloud sql instances create $COCOON_DB_INSTANCE_NAME  --tier=db-f1-micro  --region=$COCOON_REGION
gcloud sql databases create $COCOON_DB_NAME  --instance=$COCOON_DB_INSTANCE_NAME 
gcloud sql users set-password root --host=% --instance $COCOON_DB_INSTANCE_NAME --password $(cat dbpassword)

USER_NAME="s/<YOUR_MYSQL_USERNAME>/root/g"
PASSWORD="s/<YOUR_MYSQL_PASSWORD>/$(cat dbpassword)/g"
DATABASE_NAME="s/<YOUR_DATABASE_NAME>/$COCOON_DB_NAME/g"
CONNECTION_STRING="s/<YOUR_INSTANCE_CONNECTION_NAME>/$COCOON_PROJECT_ID:$COCOON_REGION:$COCOON_DB_INSTANCE_NAME/g"
sed "$USER_NAME;$PASSWORD;$CONNECTION_STRING;$DATABASE_NAME" $COCOON_HOME/rails_templates/template_database.yml > ./config/database.yml

printf "\nbeta_settings:\n  cloud_sql_instances: $COCOON_PROJECT_ID:$COCOON_REGION:$COCOON_DB_INSTANCE_NAME" >> app.yaml


# setup permissions
BUILD_MEMBER="serviceAccount:$COCOON_PROJECT_NUMBER@cloudbuild.gserviceaccount.com"
PROJECT_ROLE="roles/editor"

gcloud projects add-iam-policy-binding $COCOON_PROJECT_ID --member $BUILD_MEMBER --role $PROJECT_ROLE


# precompile assets
bundle exec bin/rails assets:precompile

#cleanup
rm dbpassword

# deploy the app
gcloud app deploy

#run db migration
bundle exec rake appengine:exec -- bundle exec rake db:migrate

gcloud app browse