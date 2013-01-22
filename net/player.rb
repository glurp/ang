# Creative Commons BY-SA :  Regis d'Aubarede <regis.aubarede@gmail.com>
###########################################################################
#                        P l a y e r
###########################################################################
# move by arrow keyboard acceleration commande, 
# eat star, move with current speed, and attractive planets
class Player
  attr_accessor :x,:y,:r,:local,:score,:id
  def initialize(window,animation,local)
	@local = local
	@top=0
	@pos=1
    @animation = animation  
    @app=window
	clear()
	@id=(Time.now.to_f*1000).to_i*1000+rand(1000)
	@r=15
	self.restart()
  end
  def restart
    @vel_x = @vel_y = @angle = @vangle = 0.0
    @x = SX/2
	@y = SY/2
	@vx,@vy=[0,0]
    @score = $INITIALE_SCORE
	@lxy=[]
	@now=Time.now.to_f * 1000
	@top=0
  end
  def clear() @pos=1 end
  def dead
	@vangle=1000
	NetClient.dead_player([id])
  end
  def fire_missile
	v=Math.sqrt(@vel_x*@vel_x+@vel_y*@vel_y)
	v=6 if v.abs<6
    vx=Gosu::offset_x(@angle,v)
    vy=Gosu::offset_y(@angle,v)
	Missile.new(@app,@animation,@local,nil,@x+10*vx,@y+10*vy,vx*1.2,vy*1.2,@r)
  end
  def warp(x, y)    @x, @y = x, y  ; end
  def turn_left()    @pos=3 ;  @vangle -= 0.3 ; end
  def turn_right()   @pos=4 ;  @vangle += 0.3 ; end  
  def accelerate(s)
    @pos= s ? 0 : 2
    @score-=3
    @vel_x += Gosu::offset_x(@angle, s ? 0.1 : -0.1)
    @vel_y += Gosu::offset_y(@angle, s ? 0.1 : -0.1)
  end
  def receive_button(command)
	@top=5
	@command=command
  end

  def move(stars,now)
	return if @x==-1000 && @y==-1000
	if @local
		a=false
		(a=true;@vel_x *= -1) if @x >= SX || @x <= 0 
		(a=true;@vel_y *= -1) if @y >= SY || @y <= 0
		@x = SX-10 if @x >= SX   && @vel_x.abs < 0.01
		@y = SY-10 if @y >= SY  && @vel_y.abs < 0.01
		@x = 10 if @x <= 0   && @vel_x.abs < 0.01
		@y = 10 if @y <= 0   && @vel_y.abs < 0.01
		
		@angle+=@vangle
		@vangle=@vangle*95.0/100
		@lxy << [@x,@y] if @vel_x!=0 && @vel_y!=0
		vx,vy=newton(stars)
		@vel_x+=vx
		@vel_y+=vy
		@vel_x.minmax(-50,+50)
		@vel_y.minmax(-50,+50)
		@x += @vel_x
		@y += @vel_y
		n=now*1000
		delta=n-@now
		if delta >= $NET_TRANSMIT
			@top+=1
			NetClient.player_is_moving([@top,n,[@x,@y],[@vel_x,@vel_y],[vx,vy],[@angle,@vangle],@score])
			@now=n
		end
	else
		@vel_x+=@vx
		@vel_y+=@vy
		@vx,@vy=[@vx/2,@vy/2]
		@x += @vel_x
		@y += @vel_y
		@angle+=@vangle
		@vangle=@vangle*95.0/100		
	end
  end
  def update_by_net(data) 
    top,t,pos,vel,acc,ang,@score=*data
	return if top<=@top
	@top=top
	
	#puts  "delta #{Time.now.to_f*1000-t} ms"
	
	@x,@y=(pos[0]+@x)/2,(pos[1]+@y)/2
	@vel_x,@vel_y=vel[0]/2,vel[1]/2
	@vx,@vy=acc
	@angle,@vangle=ang
  end

  def newton(stars)
	vx = vy = 0.0
	stars.each  do |star|
	  next if star.type
	  d=Gosu::distance(@x,@y,star.x,star.y)-15-star.r
	  dx,dy=*newton_xy1(15*15,star.r*star.r,self,star)
	  vx+=dx
	  vy+=dy
	end
	[vx,vy]
  end
  def draw(app,stars)
	img = @animation[@pos]
	img.draw_rot(@x, @y, ZOrder::Player, @angle)
    x,y=newton(stars) ; app.draw_line(@x,@y, 0xffffffff,@x+x*1000,@y+y*1000,0xffffffff)  # debug: mark gravity force
	if app.pending?
		@lxy.each_cons(2) { |p0,p1| app.draw_line(p0[0],p0[1], 0xffffff00 ,p1[0],p1[1], 0xffffff00 ) if p1} rescue nil
	elsif @lxy.size>100
		@lxy[(-1*[800,@lxy.size].min)..-1].each_cons(2) { |p0,p1| 
			app.draw_line(p0[0],p0[1], 0x33ffff00 ,p1[0],p1[1], 0x33ffff00 ) if p1
		} rescue nil
	end
	@lxy=@lxy[-5000..-1] if @lxy.size>10000
  end
  
  def collect_stars(stars)
    stars.reject!  do |star|
	  next(false) if star.x-@x > 200
	  next(false) if star.x-@x < -200
	  next(false) if star.y-@y > 200
	  next(false) if star.y-@y < -200

      if Gosu::distance(@x, @y, star.x, star.y) < (15+star.r) then
		if star.type
			@score += 120
			NetClient.star_deleted(star.index)
			true
		else
			if @vel_x !=0 || @vel_y!=0			
				@score -= 10
				@x -= 15*@vel_x
				@y -= 15*@vel_y
				@x -= -2*10*@vel_x if @x >= SX   && @vel_x == 0
				@y -= -2*10*@vel_y if @y >= SY  && @vel_y == 0
			else
				@x += (-10..+10).rand
				@y += (-10..+10).rand
			end
			@vel_x=0
			@vel_y=0
			false
		end
	  else
		false
      end
    end
	@app.finish if @score<=0
  end
  
end
