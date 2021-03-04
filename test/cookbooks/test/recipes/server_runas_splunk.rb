splunk_server_install 'default'

splunk_service 'Splunkd' do
  splunk_bin_path '/opt/splunk/bin/splunk'
end
