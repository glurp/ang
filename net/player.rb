###########################################################################
#                        P l a y e r
###########################################################################
# move by arrow keyboard acceleration commande, 
# eat star, move with current speed, and attractive planets
class Player
  attr_accessor :x,:y,:r,:score
  def initialize(window,animation,local)
	@local = local
	@top=0
	@pos=1
    @animation = animation  
    @app=window
	clear()
	@r=15
	self.restart()
  end
  def clear
    @pos=1
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

  def move(stars)
	if @local
		a=false
		(a=true;@vel_x *= -1) if @x >= SX || @x <= 0 
		(a=true;@vel_y *= -1) if @y >= SY || @y <= 0
		@x -= 10 if @x >= SX   && @vel_x == 0
		@y -= 10 if @y >= SY  && @vel_y == 0
		@x += 10 if @x <= 0   && @vel_x == 0
		@y += 10 if @y <= 0   && @vel_y == 0
		
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
		n=Time.now.to_f*1000
		delta=n-@now
		if delta>300
			@top+=1
			NetClient.player_is_moving([@top,n,[@x,@y],[@vel_x,@vel_y],[vx,vy],[@angle,@vangle]])
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
    top,t,pos,vel,acc,ang=*data
	return if top<=@top
	@top=top
	
	puts  "delta #{Time.now.to_f*1000-t} ms"
	
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
	  next if star.x-@x > 200
	  next if star.x-@x < -200
	  next if star.y-@y > 200
	  next if star.y-@y < -200

      if Gosu::distance(@x, @y, star.x, star.y) < (15+star.r) then
		if star.type
			@score += 120
			true
		else
			if @vel_x !=0 || @vel_y!=0			
				@score -= 10
				@x -= 25*@vel_x
				@y -= 25*@vel_y
				@x -= -2*25*@vel_x if @x >= SX   && @vel_x == 0
				@y -= -2*25*@vel_y if @y >= SY  && @vel_y == 0
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
	@app.looser if @score<=0
	@app.winner(@score) if 0 == (stars.select { |s| s.type }.size )
  end
  
end