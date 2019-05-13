# A class for errors 

class GraphError < StandardError
  def initialize(action, err)
    msg = "Error in graph generation while #{action}: #{err}"
    super(msg)
  end
end

class ConfigError < StandardError
  def initialize(action)
    msg = "Error updating configuration while #{action}"
    super(msg)
  end
end
