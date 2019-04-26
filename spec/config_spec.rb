require 'rspec'
require 'json'
require 'fileutils'
require 'config'

describe Config do
  let(:config_file_valid){ 'spec/fixtures/configs/config_valid' }
  let(:config_file_invalid_json){ 'spec/fixtures/configs/config_invalid_json' }
  let(:config_file_nonexistent){ 'some_bogus_file' }
  
  context 'read_config_file' do
    it 'reads an existing config file' do
      @test_config = Config.new(config_file_valid)
      @expected_hash = {"foo"=>{"roles_path"=>"~/foo/chef/roles", "cookbooks_path"=>"~/foo/chef/cookbooks"}, "bar"=>{"roles_path"=>"~/bar/chef/roles", "cookbooks_path"=>"~/bar/chef/cookbooks"}}

      expect(@test_config.read_config_file).to eql(@expected_hash)
    end

    it 'raises a ConfigError if the file contains invalid json' do
      @test_config = Config.new(config_file_invalid_json)

      expect { @test_config.read_config_file }.to raise_error(ConfigError)
    end

    it 'returns an empty hash if the file does not exist' do
      @test_config = Config.new(config_file_nonexistent)
      @expected_hash = {}

      expect(@test_config.read_config_file).to eql(@expected_hash)
    end

  end

  context 'read_config' do
    it 'returns the specified config' do
      @test_config = Config.new(config_file_valid)
      @name = 'foo'
      @expected_hash = {"roles_path"=>"~/foo/chef/roles", "cookbooks_path"=>"~/foo/chef/cookbooks"}

      expect(@test_config.read_config(@name)).to eql(@expected_hash)
    end
  end

  context 'write_config' do
    let(:new_config_file) { '/tmp/new_config' }
    let(:config_file_to_modify) { '/tmp/config_to_modify' }
    let(:config_file_baz_added_expected) { 'spec/fixtures/configs/config_baz_added_expected'}
    let(:config_file_foo_modified_expected) { 'spec/fixtures/configs/config_foo_modified_expected'}
    let(:config_foo_update) {{:name=>"foo", :roles_path=>"~/foo2/chef/roles", :cookbooks_path=>"~/foo2/chef/cookbooks"}}
    let(:config_baz) {{:name=>"baz", :roles_path=>"~/baz/chef/roles", :cookbooks_path=>"~/baz/chef/cookbooks"}}
    
    before(:each) do
      FileUtils.rm_f new_config_file
      FileUtils.rm_f config_file_to_modify
      FileUtils.cp config_file_valid, config_file_to_modify
    end
    
    after(:each) do
      FileUtils.rm_f new_config_file
      FileUtils.rm_f config_file_to_modify
    end
    
    it 'should create a new config file if one does not exist' do
      @test_config = Config.new(new_config_file)
      @test_config.write_config(config_baz)

      expect(File.file? new_config_file).to be true
    end

    it 'should add a new config to the file' do
      @test_config = Config.new(config_file_to_modify)
      @test_config.write_config(config_baz)
      @new_file_expected = JSON.parse(File.read(config_file_baz_added_expected))

      expect(@test_config.read_config_file.keys.length).to eq 3
      expect(@test_config.read_config_file).to eql @new_file_expected
    end

    it 'should overwrite an existing config if the user says yes' do
      @test_config = Config.new(config_file_to_modify)
      @config_to_write = config_foo_update
      @new_file_expected = JSON.parse(File.read(config_file_foo_modified_expected))

      allow(HighLine).to receive(:agree).and_return(true)
      @test_config.write_config(@config_to_write)

      expect(@test_config.read_config_file.keys.length).to eq 2
      expect(@test_config.read_config_file).to eql @new_file_expected
    end

    it 'should not overwrite an existing config if the user says no' do
      @test_config = Config.new(config_file_to_modify)
      @config_to_write = config_foo_update
      @new_file_expected = JSON.parse(File.read(config_file_valid))

      allow(HighLine).to receive(:agree).and_return(false)
      @test_config.write_config(@config_to_write)

      expect(@test_config.read_config_file.keys.length).to eq 2
      expect(@test_config.read_config_file).to eql @new_file_expected
    end

    it 'should return false if the config file was not updated do to user saying no' do
      @test_config = Config.new(config_file_to_modify)
      @config_to_write = config_foo_update

      allow(HighLine).to receive(:agree).and_return(false)

      expect(@test_config.write_config(@config_to_write)).to be false
    end

    it 'should return true if the config file was written' do
      @test_config = Config.new(config_file_to_modify)
      @config_to_write = config_baz

      expect(@test_config.write_config(@config_to_write)).to be true
    end
  end
end

