class Pluto::ApplManager::Dashboard < Pluto::Dashboard::Client

  def initialize(*)
    super
    @changed_applications = Set.new
  end

  def changed
    @changed_applications
  ensure
    @changed_applications = Set.new
  end

  def on_set(appl)
    @changed_applications << appl['name']
  end

  def on_rmv(appl)
    @changed_applications << appl['name']
  end

end
