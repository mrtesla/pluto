class Pluto::Node::MissingProcessDetector

  attr_reader :missing_processes
  
  def initialize(task_manager, process_manager)
    @task_manager, @process_manager = task_manager, process_manager
    @missing_processes = []
  end
  
  def call
    processes = {}
    
    @task_manager.tasks.each do |env|
      processes[env['PLUTO_PROC_UUID']] = env
    end
    
    @process_manager.processes.each do |env|
      processes.delete(env['PLUTO_PROC_UUID'])
    end
    
    @missing_processes = processes.values
  end
  
end
