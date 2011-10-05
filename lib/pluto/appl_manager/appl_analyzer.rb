class Pluto::ApplManager::ApplAnalyzer

  require 'pluto/appl_manager/analyzers/analyzer_helpers'
  require 'pluto/appl_manager/analyzers/base_analyzer'
  require 'pluto/appl_manager/analyzers/envrc_analyzer'
  require 'pluto/appl_manager/analyzers/nvm_analyzer'
  require 'pluto/appl_manager/analyzers/procfile_analyzer'
  require 'pluto/appl_manager/analyzers/rvm_analyzer'
  require 'pluto/appl_manager/analyzers/uid_gid_analyzer'
  
  ANALYZERS = [
    Pluto::ApplManager::BaseAnalyzer,
    Pluto::ApplManager::ProcfileAnalyzer,
    # Pluto::ApplManager::DashboardConcurrencyAnalyzer
    Pluto::ApplManager::UidGidAnalyzer,
    Pluto::ApplManager::RvmAnalyzer,
    Pluto::ApplManager::NvmAnalyzer,
    Pluto::ApplManager::EnvrcAnalyzer
    # Pluto::ApplManager::DashboardEnvAnalyzer
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
