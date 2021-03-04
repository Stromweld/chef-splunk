# Inspec tests for enterprise splunk on linux systems.
SPLUNK_HOME = '/opt/splunk'.freeze

control 'Enterprise Splunk' do
  title 'Verify Enterprise Splunk server installation'
  only_if { os.linux? }

  describe 'chef-splunk::server should run as "root" user' do
    describe command('ps aux | grep "splunkd --under-systemd" | head -1 | awk \'{print $1}\'') do
      its(:stdout) { should match(/root/) }
    end
  end

  describe 'chef-splunk::server listening ports' do
    describe port(8089) do
      it { should be_listening }
      its('protocols') { should include('tcp') }
    end
  end

  describe package('splunk') do
    it { should be_installed }
  end

  describe service('Splunkd') do
    it { should be_installed }
    it { should be_enabled }
    it { should be_running }
  end

  describe processes(Regexp.new('splunkd.*-p 8089 _internal_launch_under_systemd')) do
    its('users') { should include 'root' }
    it { should exist }
  end

  describe file('/etc/systemd/system/Splunkd.service') do
    it { should exist }
    it { should be_file }
  end
end

control 'Splunk admin password validation' do
  title 'Splunk admin password'
  desc 'validate that the splunk admin password has been properly set'
  only_if { os.linux? }

  describe file("#{SPLUNK_HOME}/etc/system/local/user-seed.conf") do
    it { should_not exist }
  end

  describe command("#{SPLUNK_HOME}/bin/splunk login -auth admin:Test1234!") do
    its('stderr') { should be_empty }
    its('exit_status') { should eq 0 }
  end
end
