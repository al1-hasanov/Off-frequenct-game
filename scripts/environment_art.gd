class_name EnvironmentArt
extends RefCounted
## Authored vector props/materials. All decoration stays outside interaction geometry.

static func brick(ci: CanvasItem, r: Rect2, base: Color, siding: bool = false) -> void:
	Kit.vgrad(ci,r,base.lightened(0.03),base.darkened(0.14))
	var h := 13.0 if siding else 19.0
	for row in int(r.size.y/h):
		var y := r.position.y+row*h
		ci.draw_line(Vector2(r.position.x,y),Vector2(r.end.x,y),base.darkened(0.19),1.0)
		if siding:
			ci.draw_line(Vector2(r.position.x,y+2),Vector2(r.end.x,y+2),base.lightened(0.05),1.0)
		else:
			for col in int(r.size.x/44.0):
				var x := r.position.x+col*44+(22 if row%2 else 0)
				ci.draw_line(Vector2(x,y),Vector2(x,y+h),base.darkened(0.2),1.0)
	ci.draw_rect(Rect2(r.position,Vector2(r.size.x,5)),base.lightened(0.2))
	ci.draw_rect(Rect2(r.position,Vector2(7,r.size.y)),Color(0,0,0,0.13))


static func vent(ci: CanvasItem, p: Vector2, width: float = 80.0) -> void:
	ci.draw_rect(Rect2(p,Vector2(width,28)),Color("252e2e"))
	ci.draw_rect(Rect2(p,Vector2(width,28)),Color("64716c"),false,1.0)
	for i in 5:
		ci.draw_line(p+Vector2(5,5+i*4),p+Vector2(width-5,5+i*4),Color("48564f"),1.5)


static func radiator(ci: CanvasItem, p: Vector2, width: int = 9) -> void:
	ci.draw_line(p+Vector2(-8,22),p+Vector2(width*11+3,22),Color("424a45"),5.0)
	for i in width:
		var x := p.x+i*11
		ci.draw_rect(Rect2(x,p.y,8,63),Color("747a6c"))
		ci.draw_line(Vector2(x+1,p.y+3),Vector2(x+1,p.y+59),Color("9a9a83"),1.0)
	ci.draw_line(p+Vector2(6,63),p+Vector2(6,74),Color("3b413d"),4.0)
	ci.draw_line(p+Vector2(width*11-6,63),p+Vector2(width*11-6,74),Color("3b413d"),4.0)


static func frame(ci: CanvasItem, p: Vector2, title: String, w: float = 130.0) -> void:
	ci.draw_rect(Rect2(p+Vector2(4,5),Vector2(w,72)),Color(0,0,0,0.2))
	ci.draw_rect(Rect2(p,Vector2(w,72)),Color("30362f"))
	ci.draw_rect(Rect2(p+Vector2(5,5),Vector2(w-10,62)),Color("a7aa91"))
	Kit.text(ci,p+Vector2(10,24),title,11,Color("39473e"))
	for i in 4:
		ci.draw_line(p+Vector2(10,34+i*6),p+Vector2(w-16-i%2*20,34+i*6),Color("7e8873"),1.0)


static func mug(ci: CanvasItem, p: Vector2) -> void:
	ci.draw_rect(Rect2(p,Vector2(12,15)),Color("b5c2b2"))
	ci.draw_arc(p+Vector2(13,7),4.0,-PI*.6,PI*.6,10,Color("b5c2b2"),2.0,true)
	ci.draw_line(p,p+Vector2(12,0),Color("e2ddc6"),2.0)


static func wall_props(ci: CanvasItem, id: String) -> void:
	# High wall service details lie behind the existing consoles/windows/doors.
	if id in ["corridor","receiver_room","control_room","lobby","east_corridor","sollen_office"]:
		ci.draw_line(Vector2(-100,151),Vector2(1380,151),Color("202c2b"),7.0)
		ci.draw_line(Vector2(-100,148),Vector2(1380,148),Color("52635b"),1.5)
		for x in range(0,1380,190):
			ci.draw_rect(Rect2(x,145,6,12),Color("69736a"))
		vent(ci,Vector2(1050,190),110)
		if id == "corridor":
			frame(ci,Vector2(602,225),"OBSERVATORY / 1983",140)
			radiator(ci,Vector2(908,570),10)
		elif id == "east_corridor":
			frame(ci,Vector2(270,205),"STAFF ACCESS",120)
		elif id == "lobby":
			frame(ci,Vector2(1030,215),"HALVARD STATION",160)
	elif id == "pike_radio":
		frame(ci,Vector2(548,245),"REPAIRS / EST. 1948",175)
		vent(ci,Vector2(758,188),100)
		for i in 5:
			ci.draw_arc(Vector2(570+i*30,385),14.0,0,TAU,18,Color("262d27"),3.0,true)
			ci.draw_line(Vector2(570+i*30,370),Vector2(570+i*30,348),Color("6b7967"),2.0)
		ci.draw_rect(Rect2(530,340,200,6),Color("677461"))
	elif id == "diner":
		for x in [190.0,365.0]:
			frame(ci,Vector2(x,320),"HALVARD / WINTER",110)
		ci.draw_circle(Vector2(1100,211),30,Color("c4c0a6"))
		ci.draw_circle(Vector2(1100,211),26,Color("e5dbc1"))
		ci.draw_line(Vector2(1100,211),Vector2(1114,204),Color("343b35"),2.0)
		ci.draw_line(Vector2(1100,211),Vector2(1100,190),Color("343b35"),2.0)
	elif id == "garage":
		brick(ci,Rect2(150,220,270,155),Color("454e49"))
		for i in 7:
			var x := 176+i*31
			ci.draw_circle(Vector2(x,251),5,Color("889387"))
			ci.draw_line(Vector2(x,257),Vector2(x+4,300+i%3*12),Color("889387"),4.0)
		Kit.text(ci,Vector2(158,353),"RETURN TOOLS AFTER USE",14,Color("b6b5a0"))
	elif id == "basement":
		for y in [180.0,204.0]:
			ci.draw_line(Vector2(-100,y),Vector2(1380,y),Color("292d28"),12.0)
			ci.draw_line(Vector2(-100,y-3),Vector2(1380,y-3),Color("5a6252"),2.0)
		vent(ci,Vector2(930,240),150)
	elif id == "sheriff_office":
		frame(ci,Vector2(190,215),"COUNTY / DUTY ROSTER",170)
		vent(ci,Vector2(860,190),110)
	elif id == "ash_kitchen":
		# This house is empty in the story: exposed pipes and faded paper, not new furniture.
		ci.draw_line(Vector2(310,375),Vector2(310,580),Color("817464"),5.0)
		ci.draw_line(Vector2(310,580),Vector2(380,580),Color("817464"),5.0)
		for i in 7:
			ci.draw_line(Vector2(220+i*36,300),Vector2(225+i*36,345),Color(0.12,0.1,0.08,0.18),1.0)


static func street_details(ci: CanvasItem) -> void:
	# Cornices, snow caps, drainpipes, striped awning and slushy footprints.
	for r in [Rect2(140,200,310,450),Rect2(466,300,236,350),Rect2(766,320,250,330)]:
		ci.draw_rect(Rect2(r.position-Vector2(4,2),Vector2(r.size.x+8,5)),Color("99a9ad"))
		ci.draw_line(Vector2(r.end.x-7,r.position.y+10),Vector2(r.end.x-7,640),Color("282e30"),4.0)
		ci.draw_line(Vector2(r.end.x-6,r.position.y+10),Vector2(r.end.x-6,640),Color("707976"),1.0)
	ci.draw_rect(Rect2(145,404,216,14),Color("44332c"))
	for i in 16:
		ci.draw_rect(Rect2(145+i*13.5,404,7,14),Color("806955"))
	for x in [150.0,476.0,780.0,940.0]:
		ci.draw_line(Vector2(x,540),Vector2(x+60,540),Color("9daba5"),3.0)
	for i in 34:
		var p := Vector2(-180+i*48,664+(i%3)*8)
		ci.draw_line(p,p+Vector2(13,1),Color(0.18,0.23,0.27,0.32),3.0)
	# Gutter grates and a worn kerb at the edge of the walkable road.
	for x in [76.0,708.0,1190.0]:
		ci.draw_rect(Rect2(x,685,48,9),Color("454b4c"))
		for i in 7:
			ci.draw_line(Vector2(x+3+i*6,686),Vector2(x+3+i*6,693),Color("88918d"),1.0)
	Kit.text(ci,Vector2(646,568),"OPEN",10,Color("b8c3a2"))
	Kit.text(ci,Vector2(879,563),"CLOSED",9,Color("8a8d81"))
	# Shop glass: frames and diagonal reflection, with warm light on the pavement.
	for r in [Rect2(150,420,210,130),Rect2(476,420,150,120)]:
		ci.draw_line(r.position+Vector2(10,10),r.position+Vector2(50,r.size.y-12),Color(.85,.89,.83,.16),9.0)
		ci.draw_line(Vector2(r.get_center().x,r.position.y),Vector2(r.get_center().x,r.end.y),Color("5c5b4a"),3.0)
		Kit.vgrad(ci,Rect2(r.position.x,657,r.size.x,48),Color(1,.72,.37,.13),Color(1,.72,.37,0))
	for k in 6:
		var x := 490.0+(k%3)*44
		var y := 440.0+floorf(k/3.0)*46
		for bar in 4:
			ci.draw_line(Vector2(x+4+bar*3,y+16),Vector2(x+4+bar*3,y+22),Color("998559"),1.0)
		ci.draw_circle(Vector2(x+27,y+17),2,Color("bda671"))
	# An old service cable sags across the narrow alley.
	var wire := PackedVector2Array()
	for i in 19:
		wire.append(Vector2(690+i*5,360+sin(i/18.0*PI)*13))
	ci.draw_polyline(wire,Color("161e26"),2.0,true)
	ci.draw_rect(Rect2(716,600,28,46),Color("303a3c"))
	ci.draw_rect(Rect2(713,596,34,5),Color("8b9897"))
	for i in 4:
		ci.draw_line(Vector2(720+i*6,606),Vector2(720+i*6,642),Color("485659"),1.0)
	# Lamps taper gently onto the kerb instead of a hard circular pool.
	for x in [155.0,490.0,1045.0]:
		ci.draw_colored_polygon(PackedVector2Array([Vector2(x-6,351),Vector2(x+6,351),Vector2(x+82,646),Vector2(x-82,646)]),Color(1,.7,.4,.025))


static func motes(ci: CanvasItem, time: float, floor_y: float) -> void:
	for i in 16:
		var p := Vector2(90+fposmod(i*83.7+sin(time*.2+i)*9,1120),140+fposmod(i*39.1-time*(1.0+i%3),maxf(100,floor_y-200)))
		ci.draw_circle(p,0.8,Color(.83,.89,.8,.07+.04*sin(time+i)))
