# frozen_string_literal: true

require 'spec_helper'

describe 'my_java' do

  let(:params) do
    {
     'version'             => 'installed',
     'package'             => 'java-1.8.0-openjdk',
     'architecture'        => 'x86_64',
     'java_home'           => '/usr/lib/jvm/java-1.8.0/',
     'enable_alternative'  => true,
    }
  end

  let(:pre_condition) do
    "service { 'pxp-agent': ensure => 'running' }"
  end

  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts }

      context 'defaults on class' do
        it { is_expected.to compile }
        it { is_expected.to contain_class('My_java') }
      end
      
      context 'when trusted is storefront' do
        let(:node) { 'my.example.com' }
        let(:facts) do
          os_facts.merge({ ssldir: '/path/to/file' })
        end
          
        context 'when trusted extentions include storefront_production' do
          let(:trusted_facts) { {'pp_image_name' => 'storefront_production'}}
            it { should contain_notify('storefront_production').with('withpath' => '/path/to/file/certs/my.example.com.pem',)}
          end

        context 'when trusted extentions does not include storefront_production' do
          it { should_not contain_notify('storefront_production')}
        end
      end

      context 'when environment is production' do
        context 'when enable_alternative is true' do
          it { is_expected.to contain_package('java-1.7.0-openjdk.x86_64').with('ensure' => 'installed')}
          it { is_expected.to contain_exec('update-java-alternatives').with('command' => 'alternatives --set java java-1.7.0-openjdk-x86_64') }
        end

        context 'and openjdk_architecture is 64 bit' do
          it { is_expected.to contain_package('java-1.8.0-openjdk').with('ensure' => 'installed')}
          it { is_expected.to contain_file_line('java-home-environment').with('path' => '/etc/environment')}
          it { is_expected.to contain_file_line('java-home-environment').with('line' => 'JAVA_HOME=/usr/lib/jvm/java-1.8.0/')}
        end

        context 'when package provider is yum' do
          it { is_expected.to contain_package('java-1.7.0-openjdk.x86_64').with('provider' => 'yum')}
        end
          
        context 'when package provider is apt' do
          let(:facts) do
            super().merge( { 'osfamily'  => 'Debian' } )
          end
          it { is_expected.to contain_package('java-1.7.0-openjdk.x86_64').with('provider' => 'apt')}     
        end
        
        context 'when enable_alternative is false' do
          let(:params) {{'enable_alternative' => false}}
          it { is_expected.not_to contain_package('java-1.7.0-openjdk.x86_64').with('ensure' => 'installed')} 
        end
      end

      context 'when environment is development' do
        let(:environment) { 'development' }

        context 'when enable_alternative is true' do
          context 'and openjdk_architecture is 32 bit' do
            it { is_expected.to contain_package('java-1.7.0-openjdk.i686').with('ensure' => 'installed')}
            it { is_expected.to contain_exec('update-java-alternatives').with('command' => 'alternatives --set java java-1.7.0-openjdk-i686') }        
          end

          context 'and openjdk_architecture is 64 bit' do
            it { is_expected.to contain_package('java-1.8.0-openjdk').with('ensure' => 'installed')}
            it { is_expected.to contain_file_line('java-home-environment').with('path' => '/etc/environment')}
            it { is_expected.to contain_file_line('java-home-environment').with('line' => 'JAVA_HOME=/usr/lib/jvm/java-1.8.0/')}
          end
        end

        context 'when enable_alternative is false' do
          let(:params) do
            super().merge({ 'enable_alternative' => false })
          end

          context 'and openjdk_architecture is 32 bit' do
            it { is_expected.not_to contain_package('java-1.7.0-openjdk.i686').with('ensure' => 'installed')} 
          end
          context 'and openjdk_architecture is 64 bit' do
            it { is_expected.not_to contain_package('java-1.7.0-openjdk.x86_64').with('ensure' => 'installed')} 
          end
        end
      end

      context 'when the parameters are set in the "right" way' do
        it { expect { should create_class('my_java') } }
      end
    
      context 'when the parameters are set in a wrong way' do
        let(:params) do
          super().merge({ 'enable_alternative' => 'VeryTrue' })
        end
        
        it { expect { should create_class('my_java') }.to raise_error(/expects a value of type Undef or Boolean/) }
      end
    end
  end
end