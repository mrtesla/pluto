class Pluto::Node::ServiceDetector

  def initialize(service_manager, dir=nil)
    @service_manager = service_manager
    @dir             = dir ? Pathname.new(dir) : (Pluto.root + 'services')
    @services        = Set.new
  end

  def run
    services = Set.new

    @dir.children.each do |child|
      name = child.basename.to_s

      unless child.symlink? or child.directory?
        next
      end

      while child.symlink?
        child = child.dirname + child.readlink
      end

      unless child.directory?
        next
      end

      procfile = child + 'Procfile'

      unless procfile.file?
        next
      end

      uuid = Digest::SHA1.hexdigest([
        name,
        child.to_s,
        procfile.stat.mtime.to_s
      ].join("\0"))

      services << [uuid, name, child]
    end
    
    added_services   = services  - @services
    removed_services = @services - services

    @services = services
    @service_manager.process_detected_services(added_services, removed_services)
  end

end
