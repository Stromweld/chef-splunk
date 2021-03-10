splunk_server_install 'default'

append_if_no_line 'Disable file locking check by Splunk startup' do
  line 'OPTIMISTIC_ABOUT_FILE_LOCKING = 1'
  path '/opt/splunk/etc/splunk-launch.conf'
end

splunk_service 'Splunkd' do
  splunk_bin_path '/opt/splunk/bin/splunk'
end
