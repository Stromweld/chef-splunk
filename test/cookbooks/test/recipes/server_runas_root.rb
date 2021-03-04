splunk_server_install 'default' do
  svc_user 'root'
end

splunk_service 'Splunkd' do
  splunk_bin_path '/opt/splunk/bin/splunk'
  svc_user 'root'
end
