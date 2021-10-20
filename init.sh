# create sample rails app
rails new appengine_example
cd appengine_example

# create a sample controller
rails generate controller Welcome index

# update route and index page 
cp $COCOON_HOME/rails_templates/template_index.html.erb ./app/views/welcome/index.html.erb
cp $COCOON_HOME/rails_templates/template_route.rb ./config/routes.rb

# fix bundler
bundle lock --add-platform x86_64-linux

# add deployment config for app engine
sed "s/<secret_key>/$(bundle exec rails secret)/g" $COCOON_HOME/rails_templates/template_app.yaml > app.yaml

# authorise gcloud
gcloud auth login

# create a gcp project
ruby $COCOON_HOME/clients/deploy_appengine.rb
gcloud config set project $COCOON_PROJECT_ID

# deploy the app
gcloud app create
gcloud app deploy
gcloud app browse