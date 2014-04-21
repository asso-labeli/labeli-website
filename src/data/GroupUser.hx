package data;
import sys.db.Types;

@:id(id)
@:table("v4_groupUsers")
class GroupUser extends sys.db.Object
{
	public function new(group : Group, user : User, label : String, admin : Bool)
	{
		super();

		this.created = Date.now();
		this.user = user;
		this.group = group;
		this.label = label;
		this.admin = admin;
	}

	public static function toObject(instance : GroupUser)
	{
		if(instance == null)
			return null;
		return 
		{
			id : instance.id,
			created : instance.created.getTime(),
			user : User.toObject(instance.user),
			//group : Group.toObject(instance.group),
			label : instance.label,
			admin : instance.admin
		}
	}

	public static function toArray(array : Iterable<GroupUser>)
	{
		var result = new Array<Dynamic>();
		if(array == null)
			return result;
		for(element in array)
			result.push(toObject(element));
		return result;
	}

	public var id : SId;
	public var created : Date;
	@:relation(uid) public var user : User;
	@:relation(gid) public var group : Group;
	public var label : String;
	public var admin : Bool;
}