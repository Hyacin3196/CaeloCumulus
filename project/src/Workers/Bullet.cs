using Godot;
using System;

public class Bullet : Resource
{
	private Vector3 _lastPosition; 
	private Vector3 _velNorm;
	private Vector3 _velocity;
	
	// To be set
	
	public int Index {get; set;}
	public Vector3 Position {get; set;}
	public Vector3 Velocity {
		get{ return this._velocity;}
		set{
			this._velocity = value;	
			
			this._velNorm = Velocity.Normalized();
			
			float phi = Mathf.Atan2(Velocity.z, -Velocity.x);
			this.Basis = new Basis(new Vector3(0, 1, 0), phi);
		}
	}
	public Basis Basis {get; set;}
	public uint Mask {get; set;}
	public float Mass {get; set;}
	public float LifeSpan {get; set;}
	
	public void PhysicsProcess(float delta){
		Move(delta);
		DecrementLifeSpan(delta);
	}
	
	public void Move(float delta){
		_lastPosition = Position;
		Position = Position + Velocity * delta;
	}
	
	public Transform GetTransform(){
		return new Transform(Basis, Position);
	} 
	
	public void DecrementLifeSpan(float delta){
		LifeSpan -= delta;
	}
	
	public Godot.Collections.Dictionary FindIntersection(PhysicsDirectSpaceState spaceState){
		
		Godot.Collections.Dictionary bodyDict = null;
		bodyDict = spaceState.IntersectRay(_lastPosition - _velNorm, Position + _velNorm, new Godot.Collections.Array(){}, Mask, true, true);
		if(bodyDict.Count == 0) bodyDict = spaceState.IntersectRay(Position + _velNorm, _lastPosition - _velNorm, new Godot.Collections.Array(){}, Mask, true, true);
 		return bodyDict;
	} 
	
	
}
