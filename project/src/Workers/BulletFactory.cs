using Godot;
using System;
using System.Collections.Generic;

public class BulletFactory : MultiMeshInstance
{
	
	[Export]
	private Color _color;
	[Export]
	private Color _color1;
	[Export(PropertyHint.Flags, "Normal, Flip, Rainbow")]
	private int _colorMode = 0;
	[Export]
	private float _hueRate = 1f;
	private float _hue = 0;
	private bool _colorFlip = false;
	[Export]
	private float _colorFlipInterval = 0.05f;
	private float _colorFlipTime;
	
	
	private int _numOfBullets = 5000;

	private int _activeBulletCount = 0;
	private List<Vector3> _positions = new List<Vector3>();
	private List<Vector3> _velocities = new List<Vector3>();
	private List<uint> _collisionMasks = new List<uint>();
	private List<float> _masses = new List<float>();

	private List<int> _activeIndices = new List<int>();
	private List<int> _inactiveIndices = new List<int>();
	private List<float> _timers = new List<float>();

	private MultiMesh _multiMesh;
	private Mesh _mesh;
	private SpatialMaterial _material;

	private List<String> _bulletTypes = new List<String>();

	private PhysicsDirectSpaceState _spaceState;
	
	
	// Called when the node enters the scene tree for the first time.
	public override void _Ready()
	{
		
		_colorFlipTime = _colorFlipInterval;
		
		File file = new File();
		file.Open("project//assets//bullet_types.txt", File.ModeFlags.Read);
		while(file.GetPosition() < file.GetLen())
		{
			String line = file.GetLine();
			_bulletTypes.Add(line);
		}
		file.Close();
		
		for (int i = 0; i < _bulletTypes.Count; i++)
		{
			GD.Print(_bulletTypes[i]);
		}
		
		GD.Randomize();
		
		_spaceState = GetWorld().DirectSpaceState;
		
//		_multiMesh = this.Multimesh;
		_multiMesh = new MultiMesh();
		this.Multimesh = _multiMesh;

		// Create the multimesh.
		// Set the format first.
		_multiMesh.TransformFormat = MultiMesh.TransformFormatEnum.Transform3d;
		_multiMesh.ColorFormat = MultiMesh.ColorFormatEnum.Float;
		_multiMesh.CustomDataFormat = MultiMesh.CustomDataFormatEnum.None;
		
		// Then resize (otherwise, changing the format is not allowed).
		_multiMesh.InstanceCount = _numOfBullets;
		
		// Maybe not all of them should be visible at first.
//		_multiMesh.VisibleInstanceCount = _numOfBullets;
		
		_mesh = GD.Load("res://project//assets//mesh//wave_bullet.obj") as Mesh;
		_material = new SpatialMaterial();
		_material.VertexColorUseAsAlbedo = true;
		_material.AlbedoColor = _color;
//		_material.FlagsUnshaded = true;
		_material.EmissionEnabled = true;
		_material.Emission = _color;
		_material.EmissionEnergy = 16f;
		_material.EmissionOperator = SpatialMaterial.EmissionOperatorEnum.Add;
		
//		_mesh.SurfaceSetMaterial(0, _material);
		_multiMesh.Mesh = _mesh;
		
		this.MaterialOverride = _material;
		
		
        for(int i = 0; i < _numOfBullets; i++)
        {
			_inactiveIndices.Add(i);

            var xform = new Transform(Basis.Identity, new Vector3(0, 1000, 0)); 
            _multiMesh.SetInstanceTransform(i, xform);
		}
	}
	
  // Called every frame. 'delta' is the elapsed time since the previous frame.
	public override void _PhysicsProcess(float delta)
	{
		if(_colorMode < 2 || true)
		{
		}
		else if(_colorMode < 4)
		{
			_colorFlipTime -= delta;
			if(_colorFlip && _colorFlipTime < 0)
			{
				_colorFlip = false;
				_material.Emission = _color1;
				_material.AlbedoColor = _color1;
				_colorFlipTime = _colorFlipInterval;
			}
			else if(!_colorFlip && _colorFlipTime < 0)
			{
				_colorFlip = true;
				_material.Emission = _color;
				_material.AlbedoColor = _color;
				_colorFlipTime = _colorFlipInterval;
			}
		}
		else if(_colorMode < 8)
		{
			_hue += delta * _hueRate;
			_color = Color.FromHsv(_hue, 1f, 1f, 1f);
			_material.Emission = _color;
		}
		List<int> indicesToBeRemoved = new List<int>();
		for(int i = _activeBulletCount - 1; i >= 0; i--)
		{
			if(_timers[i] > 0)
			{
				Vector3 last_position = _positions[i];
				_positions[i] = _positions[i] + _velocities[i] * delta;
				
				Vector3 vel_off = _velocities[i].Normalized();
				Godot.Collections.Dictionary body = null;
				body = _spaceState.IntersectRay(last_position - vel_off, _positions[i] + vel_off, new Godot.Collections.Array(){}, _collisionMasks[i], true, true);
				if(body.Count == 0) body = _spaceState.IntersectRay(_positions[i] + vel_off, last_position - vel_off, new Godot.Collections.Array(){}, _collisionMasks[i], true, true);

				if(body.Count != 0)
				{
					if(body["collider"] is RigidBody)
					{
						// reflection Delta is the difference between the incident and reflected vector
						Vector3 normal = (Vector3) body["normal"];
						Vector3 reflectionDelta = (2 * _velocities[i].Dot(normal)) * normal;
						RigidBody rigidBody = body["collider"] as RigidBody;
						Vector3 pos = (Vector3)body["position"] - rigidBody.Transform.origin;
						rigidBody.ApplyImpulse(pos, reflectionDelta * _masses[i]);
					} 
					indicesToBeRemoved.Add(i);
				}

				float phi = Mathf.Atan2(_velocities[i].z, -_velocities[i].x);
				Transform xform = new Transform(new Basis(new Vector3(0, 1, 0), phi), _positions[i]);
				_multiMesh.SetInstanceTransform(_activeIndices[i], xform);
				_timers[i] -= delta;
			}
			else
			{
				indicesToBeRemoved.Add(i);
			}
		}

		for(int i = 0; i < indicesToBeRemoved.Count; i++)
		{
			var index = indicesToBeRemoved[i];
			Transform xform = new Transform(new Basis(new Vector3(0, 1, 0), 0), new Vector3(0, 1000, 0));
			_multiMesh.SetInstanceTransform(_activeIndices[index], xform);
			_inactiveIndices.Add(_activeIndices[index]);
			_activeIndices.RemoveAt(index);
			_timers.RemoveAt(index);
			_positions.RemoveAt(index);
			_velocities.RemoveAt(index);
			_collisionMasks.RemoveAt(index);
		}

		// Update active bullet count
		_activeBulletCount = _activeIndices.Count;

    }
	
	public void ShootBullet(String bulletType, Vector3 position, Vector3 velocity, float lifespan, int collisionMask, float mass)
	{
		int index = _inactiveIndices[_inactiveIndices.Count-1];
		_inactiveIndices.RemoveAt(_inactiveIndices.Count-1);
		_activeIndices.Add(index);
		_timers.Add(lifespan);
		_positions.Add(position);
		_velocities.Add(velocity);
		_collisionMasks.Add(Convert.ToUInt32(collisionMask));
		_masses.Add(mass);
		_activeBulletCount = _activeIndices.Count;

		float phi = Mathf.Atan2(velocity.z, -velocity.x);
		Transform xform = new Transform(new Basis(new Vector3(0, 1, 0), phi), position);
		_multiMesh.SetInstanceTransform(index, xform);

	}
	
	public override void _Notification(int what)
	{
		if(what == MainLoop.NotificationWmQuitRequest)
		{
			QueueFree();
		}
	}
}

