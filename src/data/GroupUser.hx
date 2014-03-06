package data;
import sys.db.Types;

@:id(id)
@:table("next_groupUsers")
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

	public function getObject()
	{
		return 
		{
			id : this.id,
			created : this.created,
			user : this.user,
			group : this.group,
			label : this.label,
			admin : this.admin
		}
	}

	public var id : SId;
	public var created : Date;
	@:relation(uid) public var user : User;
	@:relation(gid) public var group : Group;
	public var label : String;
	public var admin : Bool;
}