class Pluto::Node::ServiceManager

  def initialize(task_manager, root=nil)
    @task_manager = task_manager
    @root = Pathname.new(root || Pluto.root)
  end

  def load_all
  end

  def run
  end

end
