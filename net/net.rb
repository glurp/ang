###########################################################################
#   reseau partage ANG
###########################################################################
require "socket"
require "thread"
require "ipaddr"


################ Net manager : multicast member, send to all, receive from any ##############
class NetClient
	class << self
		def init(game) 
		    @is_master=true
			@players,@players_ip,@game={},{},game
			@queue= Queue.new
			@mcast=MCast.new(self)
			Thread.new { dispatch() }
		end
		# invoked by MCast, data is string (ruby literal)
		# ["move",id,time,[x,y],[vx,vy],[a,va]]
		def receive_data(data)
			return if !(data && data[0,1]=="[")
			bdata=eval( data )
			if Array===bdata && bdata.length>1
				code,id,*bdata=bdata
				return if id==$id
				@is_master=false if id<$id 
				#puts  "#{$id} recieve : #{data}"
				case code
				when "move"
					@game.update_payers(id,bdata)
				when "connect"
					@game.init_player(id)
					@game.send_positions(id) 
				when "positions"
					@game.get_positions(id,bdata) 
				when "alive"
				when "quit"
					@game.del_player(id)
				else
					puts "recieved unknown message #{data}"
				end
			end
		end
		def dispatch()
			@mcast.send(1,["connect",$id])
			loop do
				begin
						m=@queue.pop
						#log "#{$id} send to serveur : ",m
						@mcast.send(1,m) 
				rescue Exception => e
					puts e.to_s + "\n  "+ e.backtrace.join("\n  ")
				end
			end
		end
		def player_is_moving(data)
			@queue.push(["move",$id,*data])
		end
		def send_position(data)
			@queue.push(["positions",$id,*data])
		end
		def is_stoping()
			@queue.pop while (@queue.size>2)
			@queue.push(["quit",$id])
			Thread.new { sleep(1) ; exit! }
		end
	end
end


class MCast
  MULTICAST_ADDR = "224.6.8.11"
  BIND_ADDR = "0.0.0.0"
  PORT = 6811

  def initialize(client)
    @client  = client
	socket
	listen()
  end

  def send(n,content)
    message = content.inspect
    socket.send(message, 0, MULTICAST_ADDR, PORT)
	(n-1).times { sleep(0.02); socket.send(message, 0, MULTICAST_ADDR, PORT) }
  end

  private

  def listen
    socket.bind(BIND_ADDR, PORT)

    Thread.new do
      loop do
        message, x = socket.recvfrom(1024)
		@client.receive_data(message)
      end
    end
  end


  def socket
    @socket ||= UDPSocket.open.tap do |socket|
      socket.setsockopt(Socket::IPPROTO_IP, Socket::IP_ADD_MEMBERSHIP, bind_address)
      socket.setsockopt(Socket::IPPROTO_IP, Socket::IP_MULTICAST_TTL, 1)
      socket.setsockopt(Socket::SOL_SOCKET, Socket::SO_REUSEADDR, 1) rescue nil
      socket.setsockopt(Socket::SOL_SOCKET, Socket::SO_REUSEPORT, 1) rescue nil
    end
  end

  def bind_address
    IPAddr.new(MULTICAST_ADDR).hton + IPAddr.new(BIND_ADDR).hton
  end
end
