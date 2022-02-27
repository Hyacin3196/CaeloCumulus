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

	private List<Bullet> _activeBullets;
	private List<Bullet> _inactiveBullets;

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
		
		_multiMesh = new MultiMesh();
		this.Multimesh = _multiMesh;

		_multiMesh.TransformFormat = MultiMesh.TransformFormatEnum.Transform3d;
		_multiMesh.ColorFormat = MultiMesh.ColorFormatEnum.Float;
		_multiMesh.CustomDataFormat = MultiMesh.CustomDataFormatEnum.None;
		
		_multiMesh.InstanceCount = _numOfBullets;
//		_multiMesh.VisibleInstanceCount = _numOfBullets;
		
		_mesh = GD.Load("res://project//assets//mesh//wave_bullet.obj") as Mesh;
		_material = new SpatialMaterial();
		_material.VertexColorUseAsAlbedo = true;
		_material.AlbedoColor = _color;
		_material.EmissionEnabled = true;
		_material.Emission = _color;
		_material.EmissionEnergy = 16f;
		_material.EmissionOperator = SpatialMaterial.EmissionOperatorEnum.Add;
		
		_multiMesh.Mesh = _mesh;
		
		this.MaterialOverride = _material;
		
		_inactiveBullets = new List<Bullet>();
		_activeBullets = new List<Bullet>();
		
        for(int i = 0; i < _numOfBullets; i++)
        {

            var xform = new Transform(Basis.Identity, new Vector3(0, 1000, 0)); 
            _multiMesh.SetInstanceTransform(i, xform);
			
			Bullet bullet = new Bullet();
			bullet.Index = i;
			_inactiveBullets.Add(bullet);
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
		for(int i = _activeBulletCount - 1; i >= 0; i--) {
			Bullet bullet = _activeBullets[i];
			if(bullet.LifeSpan > 0) {
				bullet.PhysicsProcess(delta);
				
				Godot.Collections.Dictionary body = bullet.FindIntersection(_spaceState);

				if(body.Count != 0)
				{
					if(body["collider"] is RigidBody)
					{
						// reflection Delta is the difference between the incident and reflected vector
						Vector3 normal = (Vector3) body["normal"];
						Vector3 reflectionDelta = (2 * bullet.Velocity.Dot(normal)) * normal;
						RigidBody rigidBody = body["collider"] as RigidBody;
						Vector3 pos = (Vector3)body["position"] - rigidBody.Transform.origin;
						rigidBody.ApplyImpulse(pos, reflectionDelta * bullet.Mass);
					} 
					indicesToBeRemoved.Add(i);
				}
				
				Transform xform = new Transform(bullet.Basis, bullet.Position);
				_multiMesh.SetInstanceTransform(bullet.Index, xform);
			} else {
				indicesToBeRemoved.Add(i);
			}
		}

		this.DeleteBullets(indicesToBeRemoved);

    }
	
	
	public Bullet GetBullet(){
		Bullet bullet = _inactiveBullets[0];
		_inactiveBullets.RemoveAt(0);
		return bullet;
	}
	
	public void ShootBullet(Bullet bullet){
		_activeBullets.Add(bullet);
		_activeBulletCount = _activeBullets.Count;
		_multiMesh.SetInstanceTransform(bullet.Index, bullet.GetTransform());
	}
	
	public void DeleteBullet(int index){
		Transform xform = new Transform(new Basis(), new Vector3(0, 1000, 0));
		_multiMesh.SetInstanceTransform(_activeBullets[index].Index, xform);
		_inactiveBullets.Add(_activeBullets[index]);
		_activeBullets.RemoveAt(index);
	}
	
	// bullet indices are in descending order
	public void DeleteBullets(List<int> bulletIndices){
		for(int i = 0; i < bulletIndices.Count; i++){
			this.DeleteBullet(bulletIndices[i]);
		}
		
		_activeBulletCount = _activeBullets.Count;
	}
	
	public override void _Notification(int what)
	{
		if(what == MainLoop.NotificationWmQuitRequest)
		{
			QueueFree();
		}
	}
}

