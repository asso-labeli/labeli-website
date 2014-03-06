package data;
import sys.db.Types;

@:id(id)
@:table("next_votes")
class Vote extends sys.db.Object
{
	public function new(group : Group, user : User, value : Int)
	{
		super();

		this.user = user;
		this.group = group;
		this.value = value;
	}

	public var id : SId;
	@:relation(uid) public var user : User;
	@:relation(gid) public var group : Group;
	public var value : Int;
}