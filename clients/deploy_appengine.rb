require "google/cloud/resource_manager"     
require "google/cloud/billing"

def create_project()
    project_name = ENV["COCOON_PROJECT_ID"]

    raise "project name is needed to create a GCP project" if project_name.nil?

    ENV["COCOON_PROJECT_ID"] = project_id = project_name.downcase.tr(" ", "-") + rand(10000).to_s

    resource_manager = Google::Cloud::ResourceManager.new
    project = resource_manager.create_project project_id,
                                              name: project_name

    p "Project created with id #{project_id}"                                              
end    

def enable_billing_account()
    project_id = ENV["COCOON_PROJECT_ID"]
    billing_account_name = ENV["COCOON_BILLING_ACCOUNT_ID"]

    raise "project id is needed to create a GCP project" if project_id.nil? || billing_account_name.nil?

    p "Enabling billing account for the project"

    billing_manager = Google::Cloud::Billing.cloud_billing_service   
    billing_manager.update_project_billing_info name: "projects/#{project_id}", 
                                                project_billing_info: {
                                                    billing_account_name: "billingAccounts/#{billing_account_name}",
                                                    billing_enabled: true,
                                                    project_id: project_id,
                                                    name: "projects/#{project_id}/billingInfo",
                                                }
end    

def main()
    create_project()
    enable_billing_account()
end

main()



