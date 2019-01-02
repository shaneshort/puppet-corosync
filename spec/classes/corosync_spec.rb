require 'spec_helper'

describe 'corosync' do
  let :params do
    { set_votequorum: false,
      multicast_address: '239.1.1.2' }
  end

  shared_examples_for 'corosync' do
    it { is_expected.to compile.with_all_deps }

    it 'does manage the corosync service' do
      is_expected.to contain_service('corosync').with(
        ensure: 'running'
      )
    end

    context 'when manage_corosync_service is false' do
      before do
        params.merge!(
          manage_corosync_service: false
        )
      end

      it 'is not managing corosync service' do
        is_expected.not_to compile
      end
    end

    context 'when set_votequorum is true' do
      before do
        params.merge!(
          set_votequorum: true
        )
      end

      context 'when quorum_members is an array with 2 items' do
        before do
          params.merge!(
            quorum_members: ['node1.test.org', 'node2.test.org']
          )
        end

        it 'configures votequorum' do
          is_expected.to contain_file('/etc/corosync/corosync.conf').with_content(
            %r{nodelist}
          )
          is_expected.to contain_file('/etc/corosync/corosync.conf').with_content(
            %r{ring0_addr\: node1\.test\.org\n\s*nodeid: 1}
          )
          is_expected.to contain_file('/etc/corosync/corosync.conf').with_content(
            %r{ring0_addr\: node2\.test\.org\n\s*nodeid: 2}
          )
          is_expected.to contain_file('/etc/corosync/corosync.conf').with_content(
            %r{two_node: 1\n}
          )
        end

        it 'supports persistent node IDs' do
          params[:quorum_members_ids] = [3, 11]
          is_expected.to contain_file('/etc/corosync/corosync.conf').with_content(
            %r{nodelist}
          )
          is_expected.to contain_file('/etc/corosync/corosync.conf').with_content(
            %r{ring0_addr\: node1\.test\.org\n\s*nodeid: 3}
          )
          is_expected.to contain_file('/etc/corosync/corosync.conf').with_content(
            %r{ring0_addr\: node2\.test\.org\n\s*nodeid: 11}
          )
        end

        it 'supports persistent node names' do
          params[:quorum_members] = ['192.168.0.1', '192.168.0.2']
          params[:quorum_members_names] = ['node1.test.org', 'node2.test.org']
          is_expected.to contain_file('/etc/corosync/corosync.conf').with_content(
            %r{nodelist}
          )
          is_expected.to contain_file('/etc/corosync/corosync.conf').with_content(
            %r{ring0_addr\: 192\.168\.0\.1\n\s*nodeid: 1\n\s*name: node1\.test\.org}
          )
          is_expected.to contain_file('/etc/corosync/corosync.conf').with_content(
            %r{ring0_addr\: 192\.168\.0\.2\n\s*nodeid: 2\n\s*name: node2\.test\.org}
          )
        end
      end

      context 'when quorum_members is set to an array with 3 items' do
        before do
          params.merge!(
            quorum_members: ['node1.test.org', 'node2.test.org', 'node3.test.org'],
            votequorum_expected_votes: 3
          )
        end

        it 'does not configure two_nodes option' do
          is_expected.not_to contain_file('/etc/corosync/corosync.conf').with_content(
            %r{two_node: 1\n}
          )
        end
      end

      context 'when quorum_members is not set and votequorum_expected_votes is set' do
        before do
          params.merge!(
            votequorum_expected_votes: 2
          )
        end

        it 'configures two_node' do
          is_expected.to contain_file('/etc/corosync/corosync.conf').with_content(
            %r{two_node: 1\n}
          )
        end
      end

      context 'when quorum_members is set to an array with 2 items and votequorum_expected_votes is set' do
        before do
          params.merge!(
            quorum_members: ['node1.test.org', 'node2.test.org'],
            votequorum_expected_votes: 2
          )
        end

        it 'configures nodelist' do
          is_expected.to contain_file('/etc/corosync/corosync.conf').with_content(
            %r{nodelist}
          )
          is_expected.to contain_file('/etc/corosync/corosync.conf').with_content(
            %r{ring0_addr\: node1\.test\.org\n\s*nodeid: 1}
          )
          is_expected.to contain_file('/etc/corosync/corosync.conf').with_content(
            %r{ring0_addr\: node2\.test\.org\n\s*nodeid: 2}
          )
          is_expected.to contain_file('/etc/corosync/corosync.conf').with_content(
            %r{two_node: 1\n}
          )
        end
      end

      context 'when quorum_members is an array of arrays' do
        before do
          params.merge!(
            quorum_members: [
              ['172.31.10.1', '172.31.11.1', '172.31.12.1'],
              ['172.31.10.2', '172.31.11.2', '172.31.12.2'],
              ['172.31.10.3', '172.31.11.3', '172.31.12.3'],
              ['172.31.10.4', '172.31.11.4', '172.31.12.4']
            ]
          )
        end

        (1..4).each do |node_id|
          it "configures rings for host #{node_id} correctly" do
            is_expected.to contain_file('/etc/corosync/corosync.conf').with_content(
              %r{ring0_addr: 172.31.10.#{node_id}\n\s*ring1_addr: 172.31.11.#{node_id}\n\s*ring2_addr: 172.31.12.#{node_id}\n\s*nodeid: #{node_id}}
            )
          end
        end

        it 'does not configure two_nodes option' do
          is_expected.not_to contain_file('/etc/corosync/corosync.conf').with_content(
            %r{two_node: 1\n}
          )
        end
      end

      context 'when quorum_members is an array of 2 arrays' do
        before do
          params.merge!(
            quorum_members: [
              ['172.31.10.1', '172.31.11.1', '172.31.12.1'],
              ['172.31.10.2', '172.31.11.2', '172.31.12.2']
            ]
          )
        end

        (1..2).each do |node_id|
          it "configures rings for host #{node_id} correctly" do
            is_expected.to contain_file('/etc/corosync/corosync.conf').with_content(
              %r{ring0_addr: 172.31.10.#{node_id}\n\s*ring1_addr: 172.31.11.#{node_id}\n\s*ring2_addr: 172.31.12.#{node_id}\n\s*nodeid: #{node_id}}
            )
          end
        end

        it 'configures two_node' do
          is_expected.to contain_file('/etc/corosync/corosync.conf').with_content(
            %r{two_node: 1\n}
          )
        end
      end
    end

    context 'when unicast is used' do
      before do
        params.merge!(
          multicast_address: :undef,
          unicast_addresses: ['192.168.1.1', '192.168.1.2']
        )
      end

      context 'when set_quorum is true' do
        before do
          params.merge!(
            set_votequorum: true,
            quorum_members: ['node1.test.org', 'node2.test.org']
          )
        end

        it 'configures votequorum' do
          is_expected.to contain_file('/etc/corosync/corosync.conf').with_content(
            %r{nodelist}
          )
          is_expected.to contain_file('/etc/corosync/corosync.conf').with_content(
            %r{ring0_addr\: node1\.test\.org\n\s*nodeid: 1}
          )
          is_expected.to contain_file('/etc/corosync/corosync.conf').with_content(
            %r{ring0_addr\: node2\.test\.org\n\s*nodeid: 2}
          )
          is_expected.to contain_file('/etc/corosync/corosync.conf').with_content(
            %r{two_node: 1\n}
          )
        end

        it 'supports persistent node IDs' do
          params[:quorum_members_ids] = [3, 11]
          is_expected.to contain_file('/etc/corosync/corosync.conf').with_content(
            %r{nodelist}
          )
          is_expected.to contain_file('/etc/corosync/corosync.conf').with_content(
            %r{ring0_addr\: node1\.test\.org\n\s*nodeid: 3}
          )
          is_expected.to contain_file('/etc/corosync/corosync.conf').with_content(
            %r{ring0_addr\: node2\.test\.org\n\s*nodeid: 11}
          )
        end

        it 'supports persistent node names' do
          params[:quorum_members] = ['192.168.0.1', '192.168.0.2']
          params[:quorum_members_names] = ['node1.test.org', 'node2.test.org']
          is_expected.to contain_file('/etc/corosync/corosync.conf').with_content(
            %r{nodelist}
          )
          is_expected.to contain_file('/etc/corosync/corosync.conf').with_content(
            %r{ring0_addr\: 192\.168\.0\.1\n\s*nodeid: 1\n\s*name: node1\.test\.org}
          )
          is_expected.to contain_file('/etc/corosync/corosync.conf').with_content(
            %r{ring0_addr\: 192\.168\.0\.2\n\s*nodeid: 2\n\s*name: node2\.test\.org}
          )
        end
      end

      context 'without secauth' do
        before do
          params.merge!(
            enable_secauth: false
          )
        end

        it { is_expected.to compile.with_all_deps }

        it 'configures secauth correctly' do
          is_expected.to contain_file('/etc/corosync/corosync.conf').with_content(
            %r{secauth:\s+off}
          )
        end
      end

      context 'with one ring' do
        before do
          params.merge!(
            bind_address:      '10.0.0.1',
            unicast_addresses: ['10.0.0.1', '10.0.0.2']
          )
        end

        it 'configures the ring properly' do
          is_expected.to contain_file('/etc/corosync/corosync.conf').with_content(
            %r{interface.*memberaddr: 10\.0\.0\.1.*memberaddr: 10\.0\.0\.2.*bindnetaddr: 10\.0\.0\.1.*ringnumber:\s+0}m
          )
        end
      end

      context 'with multiple rings ' do
        before do
          params.merge!(
            bind_address:      ['10.0.0.1', '10.0.1.1'],
            unicast_addresses: [
              [
                '10.0.0.1',
                '10.0.1.1'
              ], [
                '10.0.0.2',
                '10.0.1.2'
              ]
            ]
          )
        end

        it 'configures the rings properly' do
          is_expected.to contain_file('/etc/corosync/corosync.conf').with_content(
            %r{interface.*memberaddr: 10\.0\.0\.1.*memberaddr: 10\.0\.0\.2.*bindnetaddr: 10\.0\.0\.1.*ringnumber:\s+0.*interface.*memberaddr: 10\.0\.1\.1.*memberaddr: 10\.0\.1\.2.*bindnetaddr: 10\.0\.1\.1.*ringnumber:\s+1}m
          )
        end
      end
    end

    context 'when cluster_name is not set' do
      it do
        is_expected.to contain_file('/etc/corosync/corosync.conf').without_content(
          %r{cluster_name\:}
        )
      end
    end

    context 'when cluster_name is set' do
      before do
        params.merge!(
          cluster_name: 'hacell'
        )
      end

      it 'configures cluster_name' do
        is_expected.to contain_file('/etc/corosync/corosync.conf').with_content(
          %r{cluster_name\:\s*hacell$}
        )
      end
    end

    context 'when authkey is a string' do
      before do
        params.merge!(
          authkey_source: 'string',
          authkey: 'mysecretkey'
        )
      end
      it 'deploys authkey file' do
        is_expected.to contain_file('/etc/corosync/authkey').with_content('mysecretkey')
      end
    end

    context 'when authkey is a file' do
      before do
        params.merge!(
          authkey: '/etc/pki/tls/private/corosync.key'
        )
      end
      it 'deploys authkey file' do
        is_expected.to contain_file('/etc/corosync/authkey').with_source('/etc/pki/tls/private/corosync.key')
      end
    end

    context 'when multicast_address, unicast_addresses and cluster_name are not set' do
      before do
        params.merge!(
          multicast_address: :undef
        )
      end

      it 'raises error' do
        is_expected.to raise_error(
          Puppet::Error,
          %r{You must provide a value for multicast_address, unicast_address or cluster_name\.}
        )
      end
    end

    context 'when only cluster_name is set' do
      before do
        params.merge!(
          multicast_address: :undef,
          cluster_name: 'mycluster'
        )
      end

      it 'does not configure multicast' do
        is_expected.to contain_file('/etc/corosync/corosync.conf').without_content(
          %r{broadcast}
        )
        is_expected.to contain_file('/etc/corosync/corosync.conf').without_content(
          %r{mcastaddr}
        )
      end
    end

    context 'when log_timestamp is not set' do
      it 'does not set timestamp' do
        is_expected.to contain_file('/etc/corosync/corosync.conf').without_content(
          %r{timestamp}
        )
      end
    end

    context 'when log_timestamp is false' do
      before do
        params.merge!(
          log_timestamp: false
        )
      end

      it 'does not set timestamp' do
        is_expected.to contain_file('/etc/corosync/corosync.conf').without_content(
          %r{timestamp}
        )
      end
    end

    context 'when log_timestamp is set' do
      before do
        params.merge!(
          log_timestamp: true
        )
      end

      it 'does set timestamp' do
        is_expected.to contain_file('/etc/corosync/corosync.conf').with_content(
          %r{timestamp.*on}
        )
      end
    end

    context 'when log_file is not set' do
      it 'does set to_logfile' do
        is_expected.to contain_file('/etc/corosync/corosync.conf').with_content(
          %r{to_logfile.*yes}
        )
      end
      it 'does not set logfile' do
        is_expected.to contain_file('/etc/corosync/corosync.conf').without_content(
          %r{^\s*logfile}
        )
      end
    end

    context 'when log_file and log_file_name are set' do
      before do
        params.merge!(
          log_file: true,
          log_file_name: '/var/log/corosync/corosync.log'
        )
      end

      it 'does set to_logfile' do
        is_expected.to contain_file('/etc/corosync/corosync.conf').with_content(
          %r{to_logfile.*yes}
        )
      end
      it 'does set logfile' do
        is_expected.to contain_file('/etc/corosync/corosync.conf').with_content(
          %r{logfile.*\/var\/log\/corosync/corosync\.log}
        )
      end
    end

    context 'when log_file is disabled' do
      before do
        params.merge!(
          log_file: false
        )
      end

      it 'does not set to_logfile' do
        is_expected.to contain_file('/etc/corosync/corosync.conf').with_content(
          %r{to_logfile.*no}
        )
      end
      it 'does not set logfile' do
        is_expected.to contain_file('/etc/corosync/corosync.conf').without_content(
          %r{^\s*logfile}
        )
      end
    end

    {
      'threads' => 10,
      'rrp_mode' => 'none',
      'netmtu' => 1500,
      'token' => 3000,
      'vsftype' => 'none',
      'token_retransmits_before_loss_const' => 10,
      'join' => 50,
      'compatibility' => 'whitetank'
    }.each do |optional_parameter, possible_value|
      context "when #{optional_parameter} is not set" do
        it 'is not in corosync.conf' do
          is_expected.to contain_file('/etc/corosync/corosync.conf').without_content(
            %r{#{optional_parameter}}
          )
        end
      end

      context "when #{optional_parameter} is set" do
        before do
          params.merge!(
            optional_parameter => possible_value
          )
        end

        it 'is set in corosync.conf' do
          is_expected.to contain_file('/etc/corosync/corosync.conf').with_content(
            %r{#{optional_parameter}:\s*#{possible_value}\n}
          )
        end
      end
    end

    [:corosync, :pacemaker].each do |package|
      context "install package #{package} with default version" do
        before do
          params.merge!("package_#{package}" => true)
        end

        it "does install #{package}" do
          is_expected.to contain_package(package).with(
            ensure: 'present'
          )
        end
      end

      context "install package #{package} with custom version" do
        before do
          params.merge!(
            "package_#{package}" => true,
            "version_#{package}" => '1.1.1'
          )
        end

        it "does install #{package} with version 1.1.1" do
          is_expected.to contain_package(package).with(
            ensure: '1.1.1'
          )
        end
      end

      context "do not install #{package}" do
        before do
          params.merge!("package_#{package}" => false)
        end

        it "does not install #{package}" do
          is_expected.not_to contain_package(package)
        end
      end
    end

    context 'when set_quorum is true and quorum_members is not set' do
      before do
        params.merge!(
          set_votequorum: true,
          quorum_members: []
        )
      end

      it 'raises error' do
        is_expected.to raise_error(
          Puppet::Error,
          %r{set_votequorum is true, but no quorum_members have been passed.}
        )
      end
    end

    context 'when qdevice is enabled' do
      before do
        params.merge!(
            enable_qdevice: true,
            qdevice_host: 'qdevice-host'
        )
      end
      it 'configures the qdevice host' do
        is_expected.to contain_file('/etc/corosync/corosync.conf').with_content(
          %r{host:\s*qdevice-host\n}
        )
      end

      it 'configures the qdevice algorithm to ffsplit by default' do
        is_expected.to contain_file('/etc/corosync/corosync.conf').with_content(
            %r{algorithm:\s*ffsplit\n}
        )
      end

      it 'has tls disabled by default' do
        is_expected.to contain_file('/etc/corosync/corosync.conf').with_content(
            %r{tls:\s*off\n}
        )
      end

      it 'allows you to enable tls' do
        params.merge!(
            qdevice_tls: true
        )
        is_expected.to contain_file('/etc/corosync/corosync.conf').with_content(
            %r{tls:\s*on\n}
        )
      end
      it 'allows you to change the qdevice algorithm' do
        params.merge!(
            qdevice_algorithm: 'lms'
        )
        is_expected.to contain_file('/etc/corosync/corosync.conf').with_content(
            %r{algorithm:\s*lms\n}
        )
      end
    end

    context 'when configuring defaults for logging' do
      it 'configures stderr, syslog priority, func names' do
        is_expected.to contain_file('/etc/corosync/corosync.conf').with_content(
          %r{to_stderr:       yes}
        )
        is_expected.to contain_file('/etc/corosync/corosync.conf').with_content(
          %r{syslog_priority: info}
        )
        is_expected.not_to contain_file('/etc/corosync/corosync.conf').with_content(
          %r{function_name:   on}
        )
      end
    end
  end

  context 'on Debian platforms' do
    let :facts do
      {
        osfamily:        'Debian',
        operatingsystem: 'Debian',
        operatingsystemrelease: '8.5',
        processorcount:  '3',
        ipaddress:       '127.0.0.1'
      }
    end

    it 'validates the corosync configuration' do
      is_expected.to contain_file('/etc/corosync/corosync.conf').with_validate_cmd(
        '/usr/bin/env COROSYNC_MAIN_CONFIG_FILE=% /usr/sbin/corosync -t'
      )
    end

    it_configures 'corosync'
  end

  context 'on RedHat platforms' do
    let :facts do
      { osfamily:       'RedHat',
        processorcount: '3',
        ipaddress:      '127.0.0.1' }
    end

    context 'major version is 6' do
      before do
        facts.merge!(operatingsystemrelease: '6.12')
      end

      it_configures 'corosync'

      it 'does not manage the pacemaker service' do
        is_expected.not_to contain_service('pacemaker')
      end

      it 'does not validate the corosync configuration' do
        is_expected.to contain_file('/etc/corosync/corosync.conf').without_validate_cmd
      end
    end

    context 'major version is 7' do
      before do
        facts.merge!(operatingsystemrelease: '7.3')
      end

      it_configures 'corosync'

      it 'does manage the pacemaker service' do
        is_expected.to contain_service('pacemaker').with(
          ensure: 'running'
        )
      end

      it 'validates the corosync configuration' do
        is_expected.to contain_file('/etc/corosync/corosync.conf').with_validate_cmd(
          '/usr/bin/env COROSYNC_MAIN_CONFIG_FILE=% /usr/sbin/corosync -t'
        )
      end
    end
  end
end
