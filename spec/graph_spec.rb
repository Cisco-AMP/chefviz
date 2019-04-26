require 'rspec'
require 'graphviz'
require 'graph'
require 'config'


describe Graph do
  let(:config_file) { 'spec/fixtures/configs/config_graph_test'}
  let(:graph_name) { 'graphtest' }
  let(:config) { Config.new(config_file).read_config(graph_name) }


  context 'make_graph' do

    # Note that for n recipes we will have (n+1) nodes (not n), since we draw an additional
    # 'end' node to signify the end of the runlist.
    it 'generates a graph with (n+1) nodes for a runlist with n recipes' do
      @role = 'test_recipes_only.json'
      @graph_object = Graph.new(config, @role)

      @graph = @graph_object.make_graph
      @runlist_length = @graph_object.send(:process_role, @role).length
      @expected_nodes = @runlist_length + 1

      expect(@graph.nodes.length).to eq @expected_nodes
    end

    it 'includes only one node for each unique recipe name' do
      @role = 'test_dup_recipe.json'
      @graph_object = Graph.new(config, @role)

      @graph = @graph_object.make_graph
      @runlist_length = @graph_object.send(:process_role, @role).uniq.length
      @expected_nodes = @runlist_length + 1

      expect(@graph.nodes.length).to eq @expected_nodes
    end

    # Note that for n recipes we will have n edges (not n-1), since we draw an additional
    # 'end' node to signify the end of the runlist.
    it 'includes an edge for each recipe in the list' do
      @role = 'test_recipes_only.json'
      @graph_object = Graph.new(config, @role)

      @graph = @graph_object.make_graph
      @runlist_length = @graph_object.send(:process_role, @role).length
      @expected_edges = @runlist_length

      expect(@graph.edges.length).to eq @expected_edges
    end
  end

  context 'write_graph_file' do
    let(:role) { 'test_recipes_only' }
    let(:graph) { Graph.new(config, role) }
    let(:testfile) { '/tmp/testgraphfile' }
    let(:default_file) { "#{role}.pdf" }
    
    after(:each) do
      FileUtils.rm_f testfile
      FileUtils.rm_f default_file
    end

    it 'writes a file with the specified filename' do
      graph.write_graph_file(graph.make_graph, testfile)
      expect(File.file? testfile).to be true
    end

    it 'uses the default file name if no filename is specified' do
      graph.write_graph_file(graph.make_graph)
      expect(File.file? default_file).to be true
    end
  end
  
  context 'strip_extension' do
    let(:role) { 'test_recipes_only' }
    let(:graph) { Graph.new(config, role) }
    let(:filename) { 'myfile'}
    let(:json_ext_string) { "#{filename}.json"}
    let(:other_ext_string) { "#{filename}.txt" }
    let(:json_internal_string) { "my.jsonfile" }
    
    it 'removes .json file extensions' do
      expect(graph.send(:strip_extension, json_ext_string)).to eql filename
    end

    it 'does not remove instances of .json that are not extensions' do
      expect(graph.send(:strip_extension, json_internal_string)).to eql json_internal_string
    end

    it 'does not modify strings that do not have a .json extension' do
      expect(graph.send(:strip_extension, other_ext_string)).to eql other_ext_string
    end
  end

  context 'process_role' do
    let(:expected_runlist) { ['foo::setup', 'foo::service_start'] }

    it 'identifies included recipes' do
      @role = 'test_recipes_only.json'
      @graph = Graph.new(config, @role)
      expect(@graph.send(:process_role, @role)).to eql expected_runlist
    end

    it 'identifies included roles' do
      @role = 'test_roles_only.json'
      @graph = Graph.new(config, @role)
      expect(@graph.send(:process_role, @role)).to eql expected_runlist
    end
    
    it 'identifies explicitly specified default recipes' do
      @role = 'test_explicit_default.json'
      @graph = Graph.new(config, @role)
      expect(@graph.send(:process_role, @role)).to eql expected_runlist
    end

    it 'identifies implicitly specified default recipes' do
      @role = 'test_implicit_default.json'
      @graph = Graph.new(config, @role)
      expect(@graph.send(:process_role, @role)).to eql expected_runlist
    end

    it 'includes both instances of a duplicated recipe' do
      @role = 'test_dup_recipe.json'
      @graph = Graph.new(config, @role)
      @expected_runlist = ['foo::service_start', 'foo::setup', 'foo::service_start']
      expect(@graph.send(:process_role, @role)).to eql @expected_runlist
    end
    
    it 'handles a role passed in with no file extension' do
      @role = 'test_recipes_only'
      @graph = Graph.new(config, @role)
      expect(@graph.send(:process_role, @role)).to eql expected_runlist
    end
        
    it 'raises a GraphError if the role file has a .rb extension' do
      @role = 'test_roles_only.rb'
      @graph = Graph.new(config, @role)
      @expected_msg = "Error in graph generation while processing role: ChefViz does not yet support ruby-formatted roles! Please use JSON-formatted roles instead."
      expect{ @graph.send(:process_role, @role) }.to raise_error(GraphError)
    end
        
    it 'raises a GraphError if the role file cannot be found' do
      @role = 'bogus_role'
      @graph = Graph.new(config, @role)
      expect{ @graph.send(:process_role, @role) }.to raise_error(GraphError)
    end

    it 'raises a GraphError if the role file is not well-formed JSON' do
      @role = 'test_bad_json.json'
      @graph = Graph.new(config, @role)
      expect{ @graph.send(:process_role, @role) }.to raise_error(GraphError)
    end

    it 'raises a GraphError if the cookbook file cannot be found' do
      @role = 'test_bogus_cookbook.json'
      @graph = Graph.new(config, @role)
      expect{ @graph.send(:process_role, @role) }.to raise_error(GraphError)
    end
  end
end
