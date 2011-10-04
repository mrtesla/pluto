class Pluto::Node::ServiceManager

  def initialize(task_manager, root=nil)
    @task_manager = task_manager
    @root         = root ? Pathname.new(root) : Pluto.root
    @root         = @root + 'tmp/services'
  end
  
  def process_changes(added, removed)
    load_all unless @services
    
    removed_apps = Set.new
    added_apps   = {}
    
    removed.each do |(uuid, _, _)|
      removed_apps << uuid
      @services.delete(uuid)
      (@root + (uuid + '.serv')).unlink
    end
    
    added.each do |(uuid, name, root)|
      next if @services.key?(uuid)
      
      env = {
        'PWD'            => root.to_s,
        'PLUTO_APP_NAME' => name,
        'PLUTO_APP_UUID' => uuid
      }
      
      env = Pluto::Node::ServiceAnalyser.new.call(env)
      
      if env
        (@root + (uuid + '.serv')).open('w+', 0640) do |f|
          f.write(Yajl::Encoder.encode(env))
        end
        
        @services[uuid]  = env
        added_apps[uuid] = env
      end
    end
    
    @task_manager.process_changes(added_apps, removed_apps)
  end

private

  def load_all
    @services = {}
    
    @root.children.each do |child|
      next unless child.basename.to_s =~ /\.serv$/
      env = Yajl::Parser.parse(child.read)
      @services[env['PLUTO_APP_UUID']] = env
    end
  end

end
