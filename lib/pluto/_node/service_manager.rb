class Pluto::Node::ServiceManager

  def initialize(task_manager, root=nil)
    @task_manager = task_manager
    @root         = root ? Pathname.new(root) : Pluto.root
  end

  def load_all
    @services = {}
    
    (@root + 'run' + 'services').children.each do |child|
      env = Marshal.load(child.read)
      @services[env['APP_UUID']] = env
    end
  end
  
  def process_changes(added, removed)
    removed_apps = Set.new
    added_apps   = {}
    
    removed.each do |(uuid, _, _)|
      removed_apps << uuid
      @services.delete(uuid)
      (@root + 'run' + 'services' + (uuid + '.dat')).unlink
    end
    
    @task_manager.process_changes(added_apps, removed_apps)
  end

  def run
  end

end
