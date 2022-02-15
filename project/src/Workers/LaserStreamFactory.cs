using Godot;
using System;
using System.Linq;
using System.Collections.Generic;

struct LaserStream {
	public int count;
	public ImmediateGeometry geometry;
	public Spatial turret;
	public List<Vector3> positions;
	public List<Vector3> velocities;
	public List<float> timers;
	public Color color;
	public uint collisionMask;
	public bool continuing;
	public Vector3[] knots;
	public Vector3[] p1;
	public Vector3[] p2;
	public Vector3[] prev_knots;
	public Vector3[] prev_p1;
	public Vector3[] prev_p2;
	public int stagger;
}

public class LaserStreamFactory : Spatial {
	
	private List<LaserStream> _laserStreams;
	
	private int _laserCount = 0;
	private List<int> _countList = new List<int>();
	private List<ImmediateGeometry> _immediateGeometries = new List<ImmediateGeometry>();
	private List<Spatial> _turrets = new List<Spatial>();
	private List<List<Vector3>> _positions = new List<List<Vector3>>();
	private List<List<Vector3>> _velocities = new List<List<Vector3>>();
	private List<List<float>> _timers = new List<List<float>>();
	private List<Color> _colorList = new List<Color>();
	private List<uint> _collisionMasks = new List<uint>();
	private List<bool> _continuing = new List<bool>();
	
	private List<Vector3[]> _knots = new List<Vector3[]>();
	private List<Vector3[]> _p1 = new List<Vector3[]>();
	private List<Vector3[]> _p2 = new List<Vector3[]>();
	private List<Vector3[]> _prev_knots = new List<Vector3[]>();
	private List<Vector3[]> _prev_p1 = new List<Vector3[]>();
	private List<Vector3[]> _prev_p2 = new List<Vector3[]>();
	private List<Vector3[]> _firstControlPoints = new List<Vector3[]>();
	private List<Vector3[]> _secondControlPoints = new List<Vector3[]>();
	private List<int> _staggerList = new List<int>();

	private List<int> _inactiveIndices = new List<int>();
	private List<int> _activeIndices = new List<int>();
	
	private PhysicsDirectSpaceState _spaceState;
	
	private Spatial _level;

	// Called when the node enters the scene tree for the first time.
	public override void _Ready() {
		_laserStreams = new List<LaserStream>(16);
		
		_level = GetTree().Root.GetChild(0) as Spatial;
		// Each Dictionary will have a 
//		ImmediateGeometryInstance,
//		Turret node, 
//		ienumarable of pos, 
//		ienumarable of vel,  
//		color (ienumarable of color maybe), 
//		ienumerable of timers
		
		GD.Randomize();
		
		_spaceState = GetWorld().DirectSpaceState;
		
		Color color = new Color(1f,0f,1f,1f);
		Mesh mesh = GD.Load("res://project//assets//mesh//wave_bullet.obj") as Mesh;
		SpatialMaterial material = new SpatialMaterial();
		material.VertexColorUseAsAlbedo = true;
		material.AlbedoColor = color;
//		material.FlagsUnshaded = true;
		material.EmissionEnabled = true;
		material.Emission = color;
		material.EmissionEnergy = 256f;
		material.EmissionOperator = SpatialMaterial.EmissionOperatorEnum.Add;
		
		mesh.SurfaceSetMaterial(0, material);
		
	}
	
	public override void _Process(float delta) {
		
		float laserWidth = 1f;
		int tDensity = 10; // number of t values between knots[i] and knots[i+1]
		float tInterval = 1f / (float) tDensity; // number of t values between knots[i] and knots[i+1]
		for(int index = 0; index < _activeIndices.Count; index++) {
			if(_knots[index] != null) {
				//update control points
	//			Vector3[] knots = null;
	//
	//			if(_continuing[index])
	//			{
	//				knots = new Vector3[_countList[index] + 1];
	//				_positions[index].ToArray().CopyTo(knots, 0);
	//				knots[_countList[index]] = _turrets[index].GlobalTransform.origin;
	//			}
	//			else if(_positions[index].Count > 1)
	//			{
	//				knots = new Vector3[_countList[index]];
	//				_positions[index].ToArray().CopyTo(knots, 0);
	//			}
	//			else
	//			{
	//				knots = new Vector3[2];
	//				_positions[index].ToArray().CopyTo(knots, 0);
	//				_positions[index].ToArray().CopyTo(knots, 1);
	//			}
	//
	//			Vector3[] p1 = new Vector3[0];
	//			Vector3[] p2 = new Vector3[0];
	//			GetCurveControlPoints(knots, out p1, out p2);
				
				Vector3[] knots = _knots[index];
				Vector3[] p1 = _p1[index];
				Vector3[] p2 = _p2[index];
				
				Color color = _colorList[index];
				ImmediateGeometry geo = _immediateGeometries[index];
				
				// Clean up before drawing
				geo.Clear();
				// Begin Draw
				geo.Begin(Mesh.PrimitiveType.LineStrip);
				Vector3 point;
				Vector3 direction;
				float t = 0;
				float t1 = 0;
				Vector3 leftOffset = Vector3.Zero;
				Vector3 rightOffset = Vector3.Zero;
				Vector3 leftPos = Vector3.Zero;
				Vector3 rightPos = Vector3.Zero;
				//Loop through the points in laser
				for(int i = 0; i<knots.Length - 1; i++) {
					point = knots[i];
					direction = (p1[i] - knots[i]).Normalized();
					
					leftOffset = new Vector3(direction.z, 0, -direction.x);
					rightOffset = new Vector3(-direction.z, 0, direction.x);
					leftPos = point + leftOffset * laserWidth;
					rightPos = point + rightOffset * laserWidth;
					
					geo.SetNormal(new Vector3(0, 1, 0));
	//				geo.SetColor(color);
					geo.AddVertex(point);
	//				geo.SetNormal(new Vector3(0, 1, 0));
	//				geo.SetColor(color);
	//				geo.AddVertex(leftPos);
	//				geo.SetNormal(new Vector3(0, 1, 0));
	//				geo.SetColor(color);
	//				geo.AddVertex(rightPos);
					
					//Loop through the t-values between knots[i] and knots[i+1]
					for(int j = 1; j<tDensity; j++) {
						t = j * tInterval;
						t1 = 1f - t;
						
						point = (float)Math.Pow(t1, 3) * knots[i] +
							3 * (float)Math.Pow(t1, 2) * t * p1[i] +
							3 * t1 * (float)Math.Pow(t, 2) * p2[i] +
							(float)Math.Pow(t, 3) * knots[i+1];
						
						direction = (-3 * (float)Math.Pow(t1, 2) * knots[i] - new Vector3(1, 0, 1) +
							3 * t1 * (-3 * t + 1) * p1[i] +
							3 * (2 - 3 * t) * t * p2[i] +
							3 * (float)Math.Pow(t, 2) * knots[i+1]).Normalized();
						
						leftOffset = new Vector3(direction.z, 0, -direction.x);
						rightOffset = new Vector3(-direction.z, 0, direction.x);
						leftPos = point + leftOffset * laserWidth;
						rightPos = point + rightOffset * laserWidth;
						
						geo.SetNormal(new Vector3(0, 1, 0));
	//					geo.SetColor(color);
						geo.AddVertex(point);
	//					geo.SetNormal(new Vector3(0, 1, 0));
	//					geo.SetColor(color);
	//					geo.AddVertex(leftPos);
	//					geo.SetNormal(new Vector3(0, 1, 0));
	//					geo.SetColor(color);
	//					geo.AddVertex(rightPos);
					}
				}
				
				// Finish with knots[knots.Length - 1]
				point = knots[knots.Length - 1];
				direction = (knots[knots.Length - 1] - p2[knots.Length - 2]).Normalized();
				
				leftOffset = new Vector3(direction.z, 0, -direction.x);
				rightOffset = new Vector3(-direction.z, 0, direction.x);
				leftPos = point + leftOffset * laserWidth;
				rightPos = point + rightOffset * laserWidth;
				
				geo.SetNormal(new Vector3(0, 1, 0));
	//			geo.SetColor(color);
				geo.AddVertex(point);
	//			geo.SetNormal(new Vector3(0, 1, 0));
	//			geo.SetColor(color);
	//			geo.AddVertex(leftPos);
	//			geo.SetNormal(new Vector3(0, 1, 0));
	//			geo.SetColor(color);
	//			geo.AddVertex(rightPos);
				
				geo.End();
			}
		}
	}
	
  // Called every frame. 'delta' is the elapsed time since the previous frame.
	public override void _PhysicsProcess(float delta) {
//		if(_activeIndices.Count > 0)
//			GD.Print("index "+_activeIndices[0]);
//		GD.Print("count "+_activeIndices.Count);
//		GD.Print("count "+_inactiveIndices.Count);
		List<int> indicesToBeDeactivated = new List<int>();
		for(int i = 0; i < _activeIndices.Count; i++) {
			int index = _activeIndices[i];
//			GetTree().CallGroup("GUI","updateGUI_3", _staggerList[index]);
			List<Vector3> positionList = _positions[index];
			List<Vector3> velocityList = _velocities[index];
			List<float> timerList = _timers[index];
			
			List<int> indicesToBeRemoved = new List<int>();
			for(int j = 0; j < _countList[index]; j++) {
				// move positions with velocity
				if(timerList[j] > 0) {
					positionList[j] = positionList[j] + velocityList[j] * delta;
					timerList[j] -= delta;
				} else {
					indicesToBeRemoved.Add(j);
				}
			}
			
			for(int j = indicesToBeRemoved.Count - 1; j >= 0; j--) {
				positionList.RemoveAt(indicesToBeRemoved[j]);
				velocityList.RemoveAt(indicesToBeRemoved[j]);
				timerList.RemoveAt(indicesToBeRemoved[j]);
				_countList[index]--;
			}
			
			if(_countList[index] < 0) {
				
				
				indicesToBeDeactivated.Add(index);
			}
			
			updateControlPoints(index);
			
			if(_prev_knots[index] != null && false) {
				//When shooting and first laser knot hasn't expired, 
				// prev_knots will sometimes be shorter than current knots
				if(_prev_knots[index].Length < _knots[index].Length) {
					//duplicate the value in the 0-index 
					Vector3 duplicate;
					Vector3[] temp = _prev_knots[index];
					_prev_knots[index] = new Vector3[temp.Length + 1];
					_prev_knots[index][0] = temp[0];
					temp.CopyTo(_prev_knots[index], 1);
					_prev_p1[index] = _p1[index];
					_prev_p2[index] = _p2[index];
				}
				//When shooting and first laser knot has expired,
				// prev_knots can sometimes be longer than current knots
				
				//When shooting and first laser knot has expired,
				// prev_knots and current knots can be the same length
				// but staggered indices for the same points. 
				// i.e. knots[i] is prev_knots[i - 1]
				
				
				int tDensity = 10; // number of t values between knots[i] and knots[i+1]
				float tInterval = 1f / (float) tDensity; // number of t values between knots[i] and knots[i+1]
				float tScanInterval = 0.05f;
				Vector3[] knots = _knots[index];
				Vector3[] p1 = _p1[index];
				Vector3[] p2 = _p2[index];
				Vector3[] prev_knots = _prev_knots[index];
				Vector3[] prev_p1 = _prev_p1[index];
				Vector3[] prev_p2 = _prev_p2[index];
				for(int j = 0; j < _knots[index].Length - 1; j++) {
					Vector3[] currPoints = new Vector3[tDensity * 2]; 
					Vector3[] prevPoints= new Vector3[tDensity * 2]; 
					Vector3 point = new Vector3();
					for(int k = 0; k < tDensity; k++) {
						float t = k * tInterval;
						float t1 = 1f - t;
						
						point = (float)Math.Pow(t1, 3) * knots[j] +
							3 * (float)Math.Pow(t1, 2) * t * p1[j] +
							3 * t1 * (float)Math.Pow(t, 2) * p2[j] +
							(float)Math.Pow(t, 3) * knots[j+1];
						
						currPoints[k * 2] = new Vector3(point.x, 0.1f, point.z);
						currPoints[k * 2 + 1] = new Vector3(point.x, -0.1f, point.z);
						
						point = (float)Math.Pow(t1, 3) * prev_knots[j] +
							3 * (float)Math.Pow(t1, 2) * t * prev_p1[j] +
							3 * t1 * (float)Math.Pow(t, 2) * prev_p2[j] +
							(float)Math.Pow(t, 3) * prev_knots[j+1];
						
						GD.Print((tDensity - 1 - k) * 2 + " " + prevPoints.Length);
						prevPoints[(tDensity - 1 - k) * 2] = new Vector3(point.x, 0.1f, point.z);
						prevPoints[(tDensity - 1 - k) * 2 + 1] = new Vector3(point.x, -0.1f, point.z);
					}
					
					Vector3[] points = new Vector3[tDensity * 4]; 
					currPoints.CopyTo(points, 0);
					prevPoints.CopyTo(points, prevPoints.Length);
					
					ConvexPolygonShape shape = new ConvexPolygonShape();
					shape.Points = points;
					PhysicsShapeQueryParameters shapeQuery = new PhysicsShapeQueryParameters();
					shapeQuery.SetShape(shape);
					shapeQuery.CollisionMask = _collisionMasks[index];
					GD.Print(_spaceState.IntersectShape(shapeQuery));
				}
			}
		}
		
		
		for(int j = indicesToBeDeactivated.Count - 1; j >= 0; j--) {
			_inactiveIndices.Add(indicesToBeDeactivated[j]);
//			_level.RemoveChild(_immediateGeometries[j]);
			_activeIndices.Remove(indicesToBeDeactivated[j]);
			
//			GD.Print("index " + index);
//			GD.Print("i " + i);
			GD.Print("index " + indicesToBeDeactivated[j]);
			GD.Print("j " + j);
			GD.Print("-");
			for(int a = 0; a < _activeIndices.Count; a++) {
				GD.Print(_activeIndices[a]);
			}
			GD.Print("-");
			for(int a = 0; a < _inactiveIndices.Count; a++) {
				GD.Print(_inactiveIndices[a]);
			}
			GD.Print("-");
		}
    }
	
	public void updateControlPoints(int index) {
		//update control points
		_prev_knots[index] = _knots[index];
		_prev_p1[index] = _p1[index];
		_prev_p2[index] = _p2[index];
		if(_continuing[index]) {
			_knots[index] = new Vector3[_countList[index] + 1];
			_positions[index].ToArray().CopyTo(_knots[index], 0);
			_knots[index][_countList[index]] = _turrets[index].GlobalTransform.origin;
		} else if(_positions[index].Count > 1) {
			_knots[index] = new Vector3[_countList[index]];
			_positions[index].ToArray().CopyTo(_knots[index], 0);
		} else {
			_knots[index] = new Vector3[2];
			_positions[index].ToArray().CopyTo(_knots[index], 0);
			_positions[index].ToArray().CopyTo(_knots[index], 1);
		}
		
		Vector3[] p1 = new Vector3[0];
		Vector3[] p2 = new Vector3[0];
		GetCurveControlPoints(_knots[index], out p1, out p2);
		_p1[index] = p1;
		_p2[index] = p2;
	}
	
	public int ShootLaser(Spatial turret, int index, Vector3 position, Vector3 velocity, Color color, float lifespan, int collisionMask, bool continuing) {
		
		
		if(index < 0) {
			if(_inactiveIndices.Count > 0) {
				index = _inactiveIndices[_inactiveIndices.Count - 1];
				_activeIndices.Add(_inactiveIndices[_inactiveIndices.Count - 1]);
				_inactiveIndices.RemoveAt(_inactiveIndices.Count - 1);
				
				_turrets[index] = turret;
				
				List<Vector3> positionList = new List<Vector3>();
				positionList.Add(position);
				_positions[index] = positionList;
				
				List<Vector3> velocityList = new List<Vector3>();
				velocityList.Add(velocity);
				_velocities[index] = velocityList;
				
				_colorList[index] = color;
				
				List<float> timerList = new List<float>();
				timerList.Add(lifespan);
				_timers[index] = timerList;
				
				_collisionMasks[index] = Convert.ToUInt32(collisionMask);
				
				_countList[index] = 1;
				
				_continuing[index] = true;
				
				_knots[index] = null;
				_p1[index] = null;
				_p2[index] = null;
				_prev_knots[index] = null;
				_prev_p1[index] = null;
				_prev_p2[index] = null;
				
				_staggerList[index] = 1;
			} else {
				index = _laserCount++;
				_activeIndices.Add(index);
				ImmediateGeometry geo = new ImmediateGeometry();
				SpatialMaterial mat = new SpatialMaterial();
				mat.VertexColorUseAsAlbedo = true;
				mat.AlbedoColor = color;
				mat.EmissionEnabled = true;
				mat.Emission = color;
				mat.EmissionEnergy = 256f;
				mat.EmissionOperator = SpatialMaterial.EmissionOperatorEnum.Add;
				geo.MaterialOverride = mat;
				_immediateGeometries.Add(geo);
				
				_turrets.Add(turret);
				
				List<Vector3> positionList = new List<Vector3>();
				positionList.Add(position);
				_positions.Add(positionList);
				
				List<Vector3> velocityList = new List<Vector3>();
				velocityList.Add(velocity);
				_velocities.Add(velocityList);
				
				_colorList.Add(color);
				
				List<float> timerList = new List<float>();
				timerList.Add(lifespan);
				_timers.Add(timerList);
				
				_collisionMasks.Add(Convert.ToUInt32(collisionMask));
				
				_countList.Add(1);
				
				_continuing.Add(true);
				
				_knots.Add(null);
				_p1.Add(null);
				_p2.Add(null);
				_prev_knots.Add(null);
				_prev_p1.Add(null);
				_prev_p2.Add(null);
				
				_staggerList.Add(1);
			}
			
			_level.AddChild(_immediateGeometries[index]);
		} else {
			_positions[index].Add(position);
			_velocities[index].Add(velocity);
			_timers[index].Add(lifespan);
			_countList[index] = _countList[index] + 1;
			_staggerList[index]++;
		}
		
		if(!continuing) {
			_continuing[index] = false;
			index = -1;
		}
		return index;
	}
	
	
	
	//https://www.codeproject.com/articles/31859/draw-a-smooth-curve-through-a-set-of-2d-points-wit
	/// <summary>
	/// Get open-ended Bezier Spline Control Points.
	/// </summary>
	/// <param name="knots">Input Knot Bezier spline points.</param>
	/// <param name="firstControlPoints">Output First Control points
	/// array of knots.Length - 1 length.</param>
	/// <param name="secondControlPoints">Output Second Control points
	/// array of knots.Length - 1 length.</param>
	/// <exception cref="ArgumentNullException"><paramref name="knots"/>
	/// parameter must be not null.</exception>
	/// <exception cref="ArgumentException"><paramref name="knots"/>
	/// array must contain at least two points.</exception>
	public static void GetCurveControlPoints(Vector3[] knots,
		out Vector3[] firstControlPoints, out Vector3[] secondControlPoints) {
		if (knots == null)
			throw new ArgumentNullException("knots");
		int n = knots.Length - 1;
		if (n < 1)
			throw new ArgumentException
			("At least two knot points required", "knots");
		if (n == 1) { 
			// Special case: Bezier curve should be a straight line.
			firstControlPoints = new Vector3[1];
			// 3P1 = 2P0 + P3
			firstControlPoints[0].x = (2 * knots[0].x + knots[1].x) / 3.0f;
			firstControlPoints[0].z = (2 * knots[0].z + knots[1].z) / 3.0f;

			secondControlPoints = new Vector3[1];
			// P2 = 2P1 – P0
			secondControlPoints[0].x = 2 *
				firstControlPoints[0].x - knots[0].x;
			secondControlPoints[0].z = 2 *
				firstControlPoints[0].z - knots[0].z;
			return;
		}

		// Calculate first Bezier control points
		// Right hand side vector
		float[] rhs = new float[n];

		// Set right hand side X values
		for (int i = 1; i < n - 1; ++i)
			rhs[i] = 4 * knots[i].x + 2 * knots[i + 1].x;
		rhs[0] = knots[0].x + 2 * knots[1].x;
		rhs[n - 1] = (8 * knots[n - 1].x + knots[n].x) / 2.0f;
		// Get first control points X-values
		float[] x = GetFirstControlPoints(rhs);

		// Set right hand side Y values
		for (int i = 1; i < n - 1; ++i)
			rhs[i] = 4 * knots[i].z + 2 * knots[i + 1].z;
		rhs[0] = knots[0].z + 2 * knots[1].z;
		rhs[n - 1] = (8 * knots[n - 1].z + knots[n].z) / 2.0f;
		// Get first control points Y-values
		float[] z = GetFirstControlPoints(rhs);

		// Fill output arrays.
		firstControlPoints = new Vector3[n];
		secondControlPoints = new Vector3[n];
		for (int i = 0; i < n; ++i) {
			// First control point
			firstControlPoints[i] = new Vector3(x[i], 0, z[i]);
			// Second control point
			if (i < n - 1)
				secondControlPoints[i] = new Vector3(
					2 * knots[i + 1].x - x[i + 1], 
					0,
					2 * knots[i + 1].z - z[i + 1]);
			else
				secondControlPoints[i] = new Vector3((knots
					[n].x + x[n - 1]) / 2,
					0,
					(knots[n].z + z[n - 1]) / 2);
		}
	}

	/// <summary>
	/// Solves a tridiagonal system for one of coordinates (x or y)
	/// of first Bezier control points.
	/// </summary>
	/// <param name="rhs">Right hand side vector.</param>
	/// <returns>Solution vector.</returns>
	private static float[] GetFirstControlPoints(float[] rhs) {
		int n = rhs.Length;
		float[] x = new float[n]; // Solution vector.
		float[] tmp = new float[n]; // Temp workspace.

		float b = 2.0f;
		x[0] = rhs[0] / b;
		for (int i = 1; i < n; i++) {
			// Decomposition and forward substitution. 
			tmp[i] = 1 / b;
			b = (i < n - 1 ? 4.0f : 3.5f) - tmp[i];
			x[i] = (rhs[i] - x[i - 1]) / b;
		}
		for (int i = 1; i < n; i++)
			x[n - i - 1] -= tmp[n - i] * x[n - i]; // Backsubstitution.

		return x;
	}
	
	public override void _Notification(int what) {
		if(what == MainLoop.NotificationWmQuitRequest) {
			QueueFree();
		}
	}
}

