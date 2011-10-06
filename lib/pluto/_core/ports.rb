module Pluto::Ports
  
  def self.grab
    socket = TCPServer.new('0.0.0.0', 0)
    socket.setsockopt(Socket::SOL_SOCKET, Socket::SO_REUSEADDR, true)
    Socket.do_not_reverse_lookup = true
    port = socket.addr[1]
    socket.close
    return port
  end
  
end
