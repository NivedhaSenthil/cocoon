require "google/cloud/resource_manager"     
require "google/cloud/billing"

resource_manager = Google::Cloud::ResourceManager.new
billing_account_name = ""
project_id = ""
project_name = ""

project = resource_manager.create_project project_id,
                                          name: project_name

billing_manager = Google::Cloud::Billing.cloud_billing_service   
billing_manager.update_project_billing_info name: "projects/#{project_id}", 
                                            project_billing_info: {
                                                billing_account_name: "billingAccounts/#{billing_account_name}",
                                                billing_enabled: true,
                                                project_id: project_id,
                                                name: "projects/#{project_id}/billingInfo",
                                            }

