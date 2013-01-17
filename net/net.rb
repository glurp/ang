# Creative Commons BY-SA :  Regis d'Aubarede <regis.aubarede@gmail.com>
###########################################################################
#   reseau sharing for ANG
#    NetClient: singleton inteface main <=> net
#    MCast : multicasting encapsulation
###########################################################################
require "thread"
require "socket"
require "ipaddr"
require "zlib"	# if message is too big for a datagram, zip it
(puts "ruby version must be 1.9.3 or best (patched for multicast)";exit(1)) if RUBY_VERSION < "1.9.3"

################ Net manager : multicast member, send to all, receive from any ##############
class NetClient
	class << self
		def init(game) 
		    @is_master=true
			@trace=false
			@event_stack = Queue.new
			@players,@players_ip,@game={},{},game
			@queue= Queue.new
			@mcast=MCast.new(self)
			Thread.new { dispatch() }
		end
		def set_trace(on)
			@trace=on
		end
		def is_master() @is_master end
		def reinit_master(lid) 
			@is_master=true unless lid.any? {|id| id<$id}
		end
		# invoked by MCast, data is string (ruby literal)
		# ["move",id,time,[x,y],[vx,vy],[a,va]]
		def receive_data(data)
			return if !(data && data[0,1]=="[")
			bdata=eval( data )
			log("Received: #{bdata.inspect[0..100]} / length=#{data.size} bytes") if @trace
			if Array===bdata && bdata.length>1
				code,id,*bdata=bdata
				if id==$id
					log(" This message is from myself ! so, multicast seem ok")if @trace
					return
				end
				@is_master=false if id<$id 
				@event_stack << [code,id,bdata]
			end
		end
		# event recived by multicast, are evaluated here, 
		# event_invoke() must be called in main thread loop
		def event_invoke()
			while @event_stack.size>0
				code,id,bdata=*(@event_stack.pop)
				case code
				when "move"
					@game.update_payers(id,bdata)
				when "connect"
					@game.init_player(id)
					@game.send_positions(id) 
				when "success"
					@game.receive_success(id)
				when "echec"
					@game.receive_echec(id)
				when "positions"
					@game.get_positions(id,bdata) if id < $id
				when "star_delete"
					@game.star_deleted(bdata[0])
				when "nmissile"
					@game.new_missile(bdata)
				when "emissile"
					@game.end_missile(bdata[0])
				when "comment"
					@game.display_comment(bdata[0])
				when "dead-pl"
					@game.receive_echec(bdata[0])
				when "echo"
					recho(bdata)
				when "recho"
					@game.recho(id,*bdata) rescue p $!
				when "quit"
					@game.recho(id,*bdata) rescue nil
				else
					puts "recieved unknown message #{[code,id,data].join(", ")}"
				end rescue (puts $!.to_s + "\n  "+ $!.backtrace.join("\n  "))
			end 
		end
		def dispatch()
			@mcast.send_message(1,["connect",$id])
			loop do
				begin
						m=@queue.pop
						#log "#{$id} send to serveur : ",m
						@mcast.send_message(1,m) 
				rescue Exception => e
					puts e.to_s + "\n  "+ e.backtrace.join("\n  ")
				end
			end
		end
		def connect() 			@mcast.send_message(1,["connect",$id])	end
		def player_is_moving(data) 	@queue.push(["move",$id,*data]) 	end
		def send_success() 			@queue.push(["success",$id])		end
		def send_echec() 			@queue.push(["echec",$id]) 			end
		def send_position(data)		@queue.push(["positions",$id,*data]) end
		def star_deleted(index) 	@queue.push(["star_delete",$id,index]) end
		def comment(text)			@queue.push(["comment",$id,text]) 	end
		def new_missile(data)		@queue.push(["nmissile",$id,*data]) 	end
		def end_missile(data)		@queue.push(["emissile",$id,*data]) 	end
		def dead_player(data)		@queue.push(["dead-pl",$id,*data]) 	end
		def echo(data)				@queue.push(["echo",$id,*data]) 	end
		def recho(data)				@queue.push(["recho",$id,*data]) 	end
		def is_stoping()
			@queue.pop while (@queue.size>2)
			@queue.push(["quit",$id])
			Thread.new { sleep(1) ; exit! }
		end
	end
end


class MCast
  MULTICAST_ADDR = "224.6.1.89"
  BIND_ADDR = "0.0.0.0"
  PORT = 6811

  def initialize(client)
    @client  = client
	socket
	listen()
  end

  def send_message(n,content)
    message = content.inspect
	if message.size>1024
		message= "#" +  Zlib::Deflate.new(9).deflate(message, Zlib::FINISH)
		if message.size>1024
			puts "message size too big for a datagram !"
			return
		end
	end
    socket.send(message, 0, MULTICAST_ADDR, PORT)
	(n-1).times { sleep(0.02); socket.send(message, 0, MULTICAST_ADDR, PORT) }
  end

  private

  def listen
    socket.bind(BIND_ADDR, PORT) rescue nil

    Thread.new do
      loop do
        message, x = socket.recvfrom(1024)
		if message[0,1]=="#"
			zstream = Zlib::Inflate.new
			message = zstream.inflate(message[1..-1])
			zstream.finish
			zstream.close
		end
		@client.receive_data(message)
      end
    end
  end


  def socket
    @socket ||= UDPSocket.open.tap do |socket|
	  begin
		  socket.setsockopt(Socket::SOL_SOCKET, Socket::SO_REUSEADDR, 1) rescue nil
		  socket.setsockopt(Socket::SOL_SOCKET, Socket::SO_REUSEPORT, 1) rescue nil

		  ctx="bind()"		  
		  socket.bind(BIND_ADDR, PORT) if RUBY_PLATFORM =~ /(win|w)32$/  # for winxp
		  
		  ctx="IP_ADD_MEMBERSHIP"
		  socket.setsockopt(Socket::IPPROTO_IP, Socket::IP_ADD_MEMBERSHIP, bind_address)
		  ctx="IP_MULTICAST_TTL"
		  socket.setsockopt(Socket::IPPROTO_IP, Socket::IP_MULTICAST_TTL, 1)
	  rescue Exception => e
		puts "******************************************"
		puts "Multicast seem problematic on your system :"
		puts "   in #{ctx} :   #{$!.to_s}"
		puts "Did you have installed last version of Ruby (1.9.3p362 is ok)"
		puts "Or your network is deconnected..."
		puts "******************************************"
		sleep 5
		exit(1)
	  end
    end
  end

  def bind_address
    IPAddr.new(MULTICAST_ADDR).hton + IPAddr.new(BIND_ADDR).hton
  end
end
