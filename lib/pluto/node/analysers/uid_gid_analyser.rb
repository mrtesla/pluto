module Pluto::Node::UidGidAnalyser
  
  PROTECTED_ENV_VARS = %w(
    USER
  )
  
  def self.included(base)
    base.const_get('PROTECTED_ENV_VARS').concat(PROTECTED_ENV_VARS)
  end
  
private
  
  def process_application(env)
    super(env)
    
    env['USER'] = 'pluto'
  end
  
end