class Pluto::Node::ServiceDetector

  def initialize(service_manager, root=nil)
    @service_manager = service_manager
    @root = Pathname.new(root || Pluto.root)
  end

  def run
    services = []

    (@root + 'services').children.each do |child|
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

    @service_manager.process_detected_services(services)
  end

end
