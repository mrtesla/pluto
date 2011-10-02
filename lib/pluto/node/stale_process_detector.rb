class Pluto::Node::StaleProcessDetector

  attr_reader :stale_processes
  
  def initialize(task_manager, process_manager)
    @task_manager, @process_manager = task_manager, process_manager
    @stale_processes = []
  end
  
  def call
    processes = {}
    
    @process_manager.processes.each do |env|
      processes[env['PLUTO_PROC_UUID']] = env
    end
    
    @task_manager.tasks.each do |env|
      processes.delete(env['PLUTO_PROC_UUID'])
    end
    
    @stale_processes = processes.values
  end
  
end
