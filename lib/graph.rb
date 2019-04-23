#!/usr/bin/ruby

# Generate the call graph for a specified chef role.

require 'graphviz'
require './lib/error.rb'

class Graph

  def initialize(config, role)
    @role = role
    @config = config 
  end

  def make_graph
    g = Graphviz::Graph.new
    runlist = process_role(@role)

    runlist.each_with_index do |recipe, i|
      new_node = g.add_node("#{recipe}")
      if runlist[i+1].nil?
        next_node = g.add_node('<end>')
        new_node.connect(next_node)
      else
        next_node = g.add_node(runlist[i+1])
        new_node.connect(next_node, {:label => "  #{i}"})
      end
    end

    g
  end

  def write_graph_file(g, filename = nil)
    filename = "#{strip_extension(@role)}.pdf" if filename.nil?
    Graphviz::output(g, :path => filename)
  end
  
  private

  
  def strip_extension(name)
    # Use of array allows for extensibility once we add support for ruby-formatted roles
    ['.json'].each do |ext|
      return name.gsub!(/#{ext}\z/, '') if name.end_with? ext
    end
    name
  end

  def process_role(role)
    role_file = "#{@config['roles_path']}/#{role}"

    # At this point we only support json-formatted roles.
    # Adding support for ruby-formatted roles is future work.
    if role.end_with? '.rb'
      raise GraphError.new("processing role", "ChefViz does not yet support ruby-formatted roles! Please use JSON-formatted roles instead.")
    end
    
    # Roles specified inside other roles may not have a file extentension.
    # In such cases, attempt to find the correct extension.
    unless File.file? role_file
      # Use of array allows for extensibility once we add support for ruby-formatted roles
      role_file = ["#{role_file}.json"].each.select { |r| File.file? r }.first
      
      if role_file.nil?
        raise GraphError.new("processing role", "Could not find any file named #{role}.json or #{role}.rb in #{@config['roles_path']}.")
      end
    end
    
    begin
      role_hash = JSON.parse(File.read(role_file))
    rescue StandardError => e
      raise GraphError.new("processing role", "Could not parse #{role_file}: #{e}")
    end
    
    expand_runlist role_hash['run_list']
  end

  def expand_runlist(runlist)
    full_runlist = []
    runlist.each do |step|
      if step.include? 'role'
        /\[(?<role_name>.+)\]/ =~ step
        full_runlist.push(process_role(role_name))
      elsif (step.include? '::') && (!step.include? '::default')
        /\[(?<cookbook_name>.+)\]/ =~ step
        full_runlist << cookbook_name      
      else
        # Case of a default recipe being specified (i.e. recipe[cron] or recipe[cron::default])
        /\[(?<cookbook_name>.+)\]/ =~ step
        cookbook_name = cookbook_name.chomp('::default') if cookbook_name.end_with? '::default'
        full_runlist.push(get_default_list(cookbook_name))
      end
    end
    full_runlist.flatten
  end

  def get_default_list(cookbook)
    cookbook_file = "#{@config['cookbooks_path']}/#{cookbook}/recipes/default.rb"
    default_list = []
    if File.file? cookbook_file
      default_recipe = File.read(cookbook_file).split("\n").each do |line|
        default_list << line.split(' ').last.gsub("\"",'').gsub("'",'') if line.include? 'include_recipe'
      end
      default_list << "#{cookbook}::default" if default_list.empty?
      default_list
    else
      raise GraphError.new("expanding runlist", "Could not find cookbook file: #{cookbook_file}.")
    end
    
    default_list
  end

end
