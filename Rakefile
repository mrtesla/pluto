
GEMS = %w(
  pluto-core
  pluto-supervisor
  pluto
)

GEMS.each do |gem_name|
  task "build:#{gem_name}" do
    system("cd #{gem_name} ; rake build")
    unless $?.exitstatus == 0
      exit 1
    end
  end
  
  task "install:#{gem_name}" do
    system("cd #{gem_name} ; rake install")
    unless $?.exitstatus == 0
      exit 1
    end
  end
  
  task "build"   => "build:#{gem_name}"
  task "install" => "install:#{gem_name}"
end
