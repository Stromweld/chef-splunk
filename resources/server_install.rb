# To learn more about Custom Resources, see https://docs.chef.io/custom_resources.html
#
# Author:: Dang H. Nguyen <dang.nguyen@disney.com>
# Author:: Corey Hemminger
# Cookbook:: chef-splunk
# Resource:: server_install
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
provides :splunk_server_install
resource_name :splunk_server_install

description 'Install Splunk Server'

property :download_url, String,
         default: lazy {
           value_for_platform_family(
             windows: 'https://download.splunk.com/products/splunk/releases/8.1.2/windows/splunk-8.1.2-545206cc9f70-x64-release.msi',
             debian: 'https://download.splunk.com/products/splunk/releases/8.1.2/linux/splunk-8.1.2-545206cc9f70-linux-2.6-amd64.deb',
             default: 'https://download.splunk.com/products/splunk/releases/8.1.2/linux/splunk-8.1.2-545206cc9f70-linux-2.6-x86_64.rpm'
           )
         },
         description: 'Url to download the Unified Cloudwatch agent installer'

property :svc_user, %w(splunk root),
         default: 'splunk',
         description: 'Service runas user'

property :admin_username, String,
         default: 'admin',
         description: 'System User splunk server should runas'

property :admin_password, String,
         default: 'Test1234!',
         description: 'System User splunk server should runas'

action :install do
  description 'Perform the splunk server installation'

  install_dir = '/opt/splunk'
  dl_url = new_resource.download_url
  file_name = ::File.basename(URI.parse(dl_url).path)
  admin = new_resource.admin_username
  pass = new_resource.admin_password
  splunk_cmd = "#{install_dir}/bin/splunk"
  svc_user = new_resource.svc_user

  # Download and install splunk
  remote_file "#{Chef::Config[:file_cache_path]}/#{file_name}" do
    backup false
    source dl_url
    if platform_family?('debian')
      notifies :install, "dpkg_package[#{file_name}]", :immediately
    else
      notifies :install, "package[#{file_name}]", :immediately
    end
  end

  if platform_family?('debian')
    dpkg_package file_name do
      source "#{Chef::Config[:file_cache_path]}/#{file_name}"
    end
  else
    package file_name do
      source "#{Chef::Config[:file_cache_path]}/#{file_name}"
    end
  end

  # Setup admin user
  # Splunk will delete this file the first time splunk is started
  # it's a secure way of automating the initial admin password when installing Splunk
  file "#{install_dir}/etc/system/local/user-seed.conf" do
    content lazy {
      <<~SEED
        [user_info]
        USERNAME = #{admin}
        HASHED_PASSWORD = #{shell_out("#{splunk_cmd} hash-passwd #{pass}").stdout.strip}
      SEED
    }
    owner 'splunk'
    group 'splunk'
    mode '0640'
    not_if { ::File.exist?("#{install_dir}/etc/openldap/ldap.conf") }
  end

  # accept license
  execute "#{splunk_cmd} version --answer-yes --no-prompt --accept-license" do
    live_stream true
    creates "#{install_dir}/etc/openldap/ldap.conf"
  end

  ruby_block 'splunk_fix_file_ownership' do
    block do
      begin
        FileUtils.chown_R(svc_user, svc_user, install_dir)
      rescue Errno::ENOENT => e
        Chef::Log.warn "Possible transient file encountered in Splunk while setting ownership:\n#{e.message}"
      end
    end
    not_if { shell_out("stat -c '%U' #{install_dir}/var").stdout.eql?(svc_user) }
    subscribes :run, 'service[Splunkd]', :before
  end
end
