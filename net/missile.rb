# Creative Commons BY-SA :  Regis d'Aubarede <regis.aubarede@gmail.com>
###########################################################################
#                        P l a y e r
###########################################################################
class Missile < Player
  def initialize(window,animation,local,id,x,y,vx,vy,weight)
	super(window,animation,local)
	@id=id if id
	@age=0
	@r=weight
    @vangle = 0.0
	@angle=Math.atan2(vx,vy)
    @x,@y,@vel_x,@vel_y = x,y,vx,vy
	@vx,@vy=[0,0]
	@now=Time.now.to_f * 1000
	@top=0
	@app.add_missile(self)
	NetClient.new_missile([@id,x,y,vx,vy,weight]) unless id
  end
  def clear() @pos=5 end
  def restart() end
  
  def warp(x, y)    @x, @y = x, y  ; end

  def move(stars,now)
		@age+=1
		return(true) if @x >= SX+@r || @x+@r <= 0 || @y+@r >= SY || @y+@r <= 0
		vx,vy=newton(stars)
		@vel_x+=vx
		@vel_y+=vy
		@vel_x.minmax(-50,+50)
		@vel_y.minmax(-50,+50)
		@x += @vel_x
		@y += @vel_y
		@angle=Math.atan2(@vel_y,@vel_x)
		n=now*1000
		@now=now
		dead if local && stars.any? { |star|  ! star.type && Gosu::distance(@x, @y, star.x, star.y) < (15+star.r)/2 }
		return(false)
  end
  def update_by_net(data)  end
  def draw(app,stars)
	img = @animation[8]
	img.draw_rot(@x, @y, ZOrder::Player, 90.0+@angle*180.0/3.14159)
  end
  # test missile collision with some player(s)
  def collision_players(player)
     @age<60*5 && local && Gosu::distance(@x, @y, player.x, player.y) < (15+player.r) 
  end
  
end
