class Pluto::Disco::Client < Pluto::Core::Stream
  
  def self.register(disco, endpoint, node, type, info={})
    new("http://#{disco}/stream/register",
    'X-Pluto-Service' => Yajl::Encoder.encode(info.merge({
      'type'     => type,
      'node'     => node,
      'uuid'     => (info[:uuid] || "#{node}.#{type}"),
      'endpoint' => endpoint
    })))
  end
  
  def self.subscribe(disco, conditions={})
    headers = {}
    
    if conditions[:type]
      headers['X-Pluto-If-Type'] = conditions[:type]
    end
    
    if conditions[:node]
      headers['X-Pluto-If-Node'] = conditions[:node]
    end
    
    if conditions[:uuid]
      headers['X-Pluto-If-UUID'] = conditions[:uuid]
    end
    
    new("http://#{disco}/stream/services", headers)
  end
  
end
