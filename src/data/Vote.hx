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
		created = Date.now();
	}

	public static function toObject(instance : Vote)
	{
		if(instance == null)
			return null;
		return
		{
			id : instance.id,
			user : User.toObject(instance.user),
			group : Group.toObject(instance.group),
			created : instance.created.getTime(),
			value : instance.value
		};
	}

	public static function toArray(array : Iterable<Vote>)
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
	public var value : Int;
}