extends Node

enum {NONE, POINT, SEGMENT, RAY_POSITIVE, RAY_NEGATIVE}

func FindIntersection_1(u0:float, u1:float, v:float, overlap:Array):
	var numValid
	if u1>v:
		numValid=2
		overlap[0]=max(u0,v)
		overlap[1]=u1
	elif u1==v:
		numValid=1
		overlap[0]=v
	else: #u1<v
		numValid=0
	return numValid

func FindIntersection_2(u0:float, u1:float, v0:float, v1:float, overlap:Array):
	var numValid
	if u1<v0||v1<u0:
		numValid=0
	elif v0<u1:
		if u0<v1 :
			overlap[0] = v0 if u0<v0 else u0
			overlap[1] = v1 if u1>v1 else u1
			if overlap[0]<overlap[1] :
				numValid=2
			else:
				numValid=1
		else: #u0==v1
			overlap[0]=u0
			overlap[1]=u0
			numValid=1
	else: #u1==v0
		overlap[0]=v0
		overlap[1]=v0
		numValid=1
		return numValid

# The returned ’int’ is one of NONE, POINT, SEGMENT, RAYPOSITIVE or RAYNEGATIVE.
# The returned t[] and P[] values areas described previously.
func FindIntersection(line:Dictionary, cone:Dictionary, t:Array, P:Array):
	var intersectionType:int = DoQuery(line['pos'], line['vel'], cone, t)
	var intersection = ComputePoints(intersectionType, line['pos'], line['vel'], t, P)
	return [t, intersection, intersectionType]

# Where P is an array of 2 Vector3
func ComputePoints(intersectionType:int, origin:Vector3, direction:Vector3, t:Array, P:Array):
	"""match intersectionType:
		NONE:
			P[0] = null
			P[1] = null
		POINT:
			P[0] = origin+t[0]*direction
			P[1] = null
		SEGMENT:
			P[0] = origin+t[0]*direction
			P[1] = origin+t[1]*direction
		RAY_POSITIVE:
			P[0] = origin+t[0]*direction
			P[1] = null
		RAY_NEGATIVE:
			P[0] = null
			P[1] = origin+t[1]*direction
	"""
	if P[0] != null && t[0] != null:
		P[0] = origin + t[0] * direction
	if P[1] != null && t[1] != null:
		P[1] = origin + t[1] * direction
	return P

func DoQuery(P:Vector3, U:Vector3, cone:Dictionary, t:Array):
	# Arrange for an acute angle between the cone direction and line direction.
	# This simplifies the logic later in the code, and it supports additional
	# queries involving rays or segments instead of lines.
	var intersectionType:int;
	var DdU:float = cone['axis'].dot(U)
	if DdU >= 0:
		intersectionType = DoQuerySpecial(P, U, cone, t)
	else:
		intersectionType = DoQuerySpecial(P, -U, cone, t)
		t[0] = -t[0]
		t[1] = -t[1]
		
		# swap
		var i = t[0]
		t[0] = t[1]
		t[1] = i
		
		if intersectionType == RAY_POSITIVE:
			intersectionType = RAY_NEGATIVE
	
	return intersectionType

func DoQuerySpecial(P:Vector3, U:Vector3, cone:Dictionary, t:Array):
	#Computethequadraticcoefficients.
	var PmV:Vector3 = P-(cone['pos'])
	var DdU:float = cone['axis'].dot(U)
	var UdU:float = U.dot(U)
	var DdPmV:float = cone['axis'].dot(PmV)
	var UdPmV:float = U.dot(PmV)
	var PmVdPmV:float = PmV.dot(PmV)
	var c2:float = DdU*DdU-cone['cosThetaSqr']*UdU
	var c1:float = DdU*DdPmV-cone['cosThetaSqr']*UdPmV
	var c0:float = DdPmV*DdPmV-cone['cosThetaSqr']*PmVdPmV
	if c2!=0:
		var discr = c1*c1-c0*c2
		if discr<0:
			## no intersection with line and cone
			## target is faster than bullet and there is no way for bullet to hit target
			return CaseC2NotZeroDiscrNeg(t)
		elif discr>0:
			## cases (a), (b), and (c) can occur. (a) occurs when target is faster but has 2 points of contact. (b) occurs when target is faster and line interects the negative cone only thus target is unhittable. (c) occurs when target is slower than bullet, guaranteeing 1 non-vertex point of contact.
			return CaseC2NotZeroDiscrPos(c1, c2, discr, DdU, DdPmV, cone, t)
		else:
			## cases (d), (e), and (f) can occur.
			## line hits cone only at one point, can be at the vertex or cone surface
			return CaseC2NotZeroDiscrZero(c1, c2, UdU, UdPmV, DdU, DdPmV, cone, t)
	elif c1!=0:
		## target is same speed as bullet
		## only one intersection
		## if intersection is in the past, just set the trajectory to target velocity
		return CaseC2ZeroC1NotZero(c0, c1, DdU, DdPmV, cone, t)
	else:
		## target is same speed as bullet
		## line is on cone surface, 
		## just set the trajectory to target velocity
		return CaseC2ZeroC1Zero(c0, UdU, UdPmV, DdU, DdPmV, cone, t)

func CaseC2NotZeroDiscrNeg(t:Array):
	# Block 0.The quadratic polynomial has no real-valued roots. The line does not intersect the double-sided cone.
	return SetEmpty(t)

func CaseC2NotZeroDiscrPos(c1:float, c2:float, discr:float, DdU:float, DdPmV:float, cone:Dictionary, t:Array):
	
	# The quadratic has two distinct real-valued roots, t0 and t1 with t0<t1. Also compute the signed
	# heights at the intersection points, h0 and h1 with h0<=h1. The ordering is guaranteed because we
	# have arranged for the input line to satisfy DdU>=0.
	var x:float = -c1/c2
	var y:float = 1/c2 if c2>0 else -1/c2
	var t0:float = x-y*sqrt(discr)
	var t1:float = x+y*sqrt(discr)
	var h0:float = t0*DdU+DdPmV
	var h1:float = t1*DdU+DdPmV
	if h0 >= 0:
		# Block 1 , Figure 2(a). The line intersects the positive cone in two points.
		return SetSegmentClamp(t0, t1, h0, h1, DdU, DdPmV, cone, t)
	elif h1 <= 0:
		# Block 2 , Figure 2(b). The line intersects the negative cone in two points.
		return SetEmpty(t)
	else:#h0<0<h1
	# Block 3 , Figure 2(c). The line intersects the positive cone in a single point and the negative cone in a single point.
		return SetRayClamp(h1, DdU, DdPmV, cone, t)

func CaseC2NotZeroDiscrZero(c1:float, c2:float, UdU:float, UdPmV:float, DdU:float, DdPmV:float, cone:Dictionary, t:Array):
	var t0:float = -c1/c2
	if t0*UdU+UdPmV == 0:
		# To get here , it must be that V = P + (-c1 / c2 ) * U, where U is not necessarily a unit-length
		# vector. The line intersects the cone vertex.
		if c2 < 0:
			# Block 4, Figure 2(d). The line is outside the double-sided cone and intersects it only at V.
			var h:float = 0
			return SetPointClamp (t0, h, cone, t)
		else:
			# Block 5, Figure 2(e). The line is inside the double-sided cone, so the intersection is a ray
			# with origin V.
			var h:float = 0
			return SetRayClamp (h, DdU, DdPmV, cone, t)
	else:
		# The line is tangent to the cone at a point different from the vertex.
		var h:float = t0 * DdU + DdPmV;
		if h >= 0:
			# Block 6, Figure 2(f). The line is tangent to the positive cone.
			return SetPointClamp(t0, h, cone, t)
		else:
			# Block 7. The line is tangent to the negative cone.
			return SetEmpty(t)

func CaseC2ZeroC1NotZero(c0:float, c1:float, DdU:float, DdPmV:float, cone:Dictionary, t:Array):
	# U is a direction vector on the cone boundary. Compute the t-value for the intersection point
	# and compute the corresponding height h to determine whether that point is on the positive cone
	# or negative cone .
	var t0:float = -c0 / ( 2 * c1 )
	var h:float = t0 * DdU + DdPmV
	if h > 0:
		# Block 8, Figure 3(a). The line intersects the positive cone   and the ray of intersection is
		# interior to the positive cone. The intersection is a ray or segment.
		return SetRayClamp(h, DdU, DdPmV, cone, t)
	else:
		# Block 9, Figure 3(b). The line intersects the negative cone and the ray of intersection is
		# interior to the negative cone.
		return SetEmpty(t)

func CaseC2ZeroC1Zero(c0:float, UdU:float, UdPmV:float, DdU:float, DdPmV:float, cone:Dictionary, t:Array):
	if  c0 != 0 :
		# Block 10. The line does not intersect the double-sided cone.
		return SetEmpty(t);
	else:
		# Block 11, Figure 4. The line is on the cone boundary. The intersection with the positive cone
		# is a ray that contains the cone vertex. The intersection is either a ray or segment.
		var t0:float = -UdPmV / UdU;
		var h:float = t0 * DdU + DdPmV;

func SetEmpty(t:Array):
	t[0] = null
	t[1] = null
	return NONE;

func SetPoint(t0:float, t:Array):
	t[0] = t0;
	t[1] = null;
	return POINT;


func SetSegment(t0:float, t1:float, t:Array):
	t[0] = t0;
	t[1] = t1;
	return SEGMENT;

func SetRayPositive(t0:float, t:Array):
	t[0] = t0
	t[1] = null
	return RAY_POSITIVE;

func SetRayNegative(t1:float, t:Array):
	t[0] = null;
	t[1] = t1;
	return RAY_NEGATIVE;

func SetPointClamp(t0:float, h0:float, cone:Dictionary, t:Array):
	return SetPoint(t0,t)

func SetSegmentClamp(t0:float, t1:float, h0:float, h1:float, DdU:float, DdPmV:float, cone:Dictionary, t:Array):
	if h1>h0:
		var numValid;
		var overlap = [0, 0];
		if cone.isFinite:
			numValid = FindIntersection_2(h0, h1, cone['hmin'], cone['hmax'], overlap)
		else:
			numValid = FindIntersection_1(h0, h1, cone['hmin'], overlap)
		
		if numValid == 2:
			#S0.
			t0 = (overlap[0]-DdPmV)/DdU
			t1 = (overlap[1]-DdPmV)/DdU
			return SetSegment(t0, t1, t)
			
		elif numValid == 1:
			#S1.
			t0 = (overlap[0]-DdPmV)/DdU;
			return SetPoint(t0, t);
		else:# numValid == 0
			#S2.
			return SetEmpty(t)
	else:# h1 == h0
		return SetSegment(t0, t1, t)


func SetRayClamp(h:float, DdU:float, DdPmV:float, cone:Dictionary, t:Array):
	if cone['isFinite']:
		var overlap = [0, 0]
		var numValid = FindIntersection_1(cone['hmin'], cone['hmax'], h, overlap)
		if numValid == 2:
			#R0.
			return SetSegment((overlap[0]-DdPmV)/DdU, (overlap[1]-DdPmV)/DdU, t)
		elif numValid == 1:
			#R1.
			return SetPoint((overlap[0]-DdPmV)/DdU, t)
		else:# numValid == 0
			#R2.
			return SetEmpty(t)
	else:
		#R3.
		return SetRayPositive((max(cone['hmin'], h)-DdPmV)/DdU, t)
