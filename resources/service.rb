# To learn more about Custom Resources, see https://docs.chef.io/custom_resources.html
#
# Author:: Dang H. Nguyen <dang.nguyen@disney.com>
# Author:: Corey Hemminger
# Cookbook:: chef-splunk
# Resource:: service
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
provides :splunk_service
resource_name :splunk_service

description 'Configure Splunk service'

property :service_name, String,
         name_property: true,
         description: 'Systemd service name'

property :splunk_bin_path, String,
         required: true,
         description: 'Path to splunk binary'

property :svc_user, %w(splunk root),
         default: 'splunk',
         description: 'Service runas user'

property :systemd, [true, false],
         default: true,
         description: ''

action :start do
  description 'Setup Splunk Service'

  # Setup admin user for website if user is defined
  splunk_bin = new_resource.splunk_bin_path
  svc_name = new_resource.service_name
  svc_user = new_resource.svc_user
  sysd = new_resource.systemd ? 1 : 0

  # Create systemd service and start splunk server
  execute "#{splunk_bin} enable boot-start -user '#{svc_user}' -systemd-managed #{sysd} --accept-license" do
    live_stream true
    creates "/etc/systemd/system/#{svc_name}.service"
  end

  service 'splunk' do
    service_name svc_name
    action [:enable, :start]
  end
end
