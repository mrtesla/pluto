class Pluto::Node::ServiceAnalyser

  ANALYZERS = [
    Pluto::Node::BaseAnalyser,
    Pluto::Node::ProcfileAnalyser,
    # Pluto::Node::DashboardConcurrencyAnalyser
    # Pluto::Node::UidGidAnalyser
    Pluto::Node::RvmAnalyser,
    Pluto::Node::NvmAnalyser,
    Pluto::Node::EnvrcAnalyser
    # Pluto::Node::DashboardEnvAnalyser
  ]

  def initialize
    @analyzers = ANALYZERS.map { |k| k.new }
  end

  def call(env)
    @analyzers.each do |analyzer|
      env = analyzer.call(env)
      return nil unless env
    end
    return env
  end

end
