# Policyfile.rb - Describe how you want Chef Infra Client to build your system.
#
# For more information on the Policyfile feature, visit
# https://docs.chef.io/policyfile.html

# A name that describes what the system you're building with Chef does.
name 'chef-splunk'

# Where to find external cookbooks:
default_source :supermarket

# run_list: chef-client will run these recipes in the order specified.
run_list 'test::server_runas_root'
named_run_list :server_runas_root, 'test::server_runas_root'
named_run_list :server_runas_splunk, 'test::server_runas_splunk'

# Specify a custom source for a single cookbook:
cookbook 'chef-splunk', path: '.'
cookbook 'test', path: './test/cookbooks/test'
cookbook 'test_old', path: './test/fixtures/test_old'
