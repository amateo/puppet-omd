require 'spec_helper'

describe 'omd' do
  context 'supported operating systems' do
    ['Debian', 'RedHat'].each do |osfamily|
      describe "omd class without any parameters on #{osfamily}" do
        let(:params) {{ }}
        let(:facts) {{
          :osfamily => osfamily,
        }}

        it { should compile.with_all_deps }

        it { should contain_class('omd::params') }
        it { should contain_class('omd::install').that_comes_before('omd::config') }
        it { should contain_class('omd::config') }
        it { should contain_class('omd::service').that_subscribes_to('omd::config') }

        it { should contain_service('omd') }
        it { should contain_package('omd').with_ensure('present') }
      end
    end
  end

  context 'unsupported operating system' do
    describe 'omd class without any parameters on Solaris/Nexenta' do
      let(:facts) {{
        :osfamily        => 'Solaris',
        :operatingsystem => 'Nexenta',
      }}

      it { expect { should contain_package('omd') }.to raise_error(Puppet::Error, /Nexenta not supported/) }
    end
  end
end
