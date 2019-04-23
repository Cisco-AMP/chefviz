# Class for managing the ChefViz config file
require 'highline'
class Config

  def initialize(config_file)
    @config_file = config_file
  end

  # Read the configuration file and return a hash
  def read_config_file
    config_hash = {}
    if File.file? @config_file
      begin
        config_hash = JSON.parse(File.read(@config_file))
      rescue StandardError => e
        raise ConfigError.new("parsing configuration file: #{e}")
      end
    end
    config_hash
  end

  # Read the configuration for a specific key and return a hash
  def read_config(name)
    read_config_file[name]
  end

  # Generate a formatted hash appropriate for our file structure
  def format_hash(key, input_hash)
    formatted_hash = {}
    formatted_hash[key] = input_hash.dup.tap { |input| input.delete(:name) }
    formatted_hash
  end
  
  # Write a new config into the file
  def write_config(new_config)
    config_to_write = {}
    formatted_config = {}
    new_name = new_config[:name]

    # First format the input hash to be appropriate for our file format
    formatted_config = format_hash(new_name, new_config)
    current_config = read_config_file

    if current_config.key? new_name
      return false unless HighLine.agree("Config entry for #{new_name} already exists. Really overwrite? [y/n]")

      config_to_write = current_config
      config_to_write[new_name] = formatted_config[new_name]
    else
      config_to_write = current_config.merge formatted_config
    end
    config_file = File.open(@config_file, 'w')
    config_file.puts config_to_write.to_json
    config_file.close
    return true
  end
end




