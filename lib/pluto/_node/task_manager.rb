class Pluto::TaskManager::TaskManager

  def initialize

  end

  def process_changes(changed, removed)
    removed.each do |app_uuid|
      @tasks.each do |task_uuid, env|
        if env['PLUTO_APP_UUID'] == app_uuid
          @tasks.delete(task_uuid)
        end
      end
    end

  end

end