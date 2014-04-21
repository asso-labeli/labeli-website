package data;
import sys.db.Types;

@:id(id)
@:table("v4_groups")
class Group extends sys.db.Object
{
	//enum GroupType
	//{
	public static var PROJECT = 0;
	public static var TEAM = 1;
	public static var EVENT = 2;
	//}

	//enum GroupStatus
	//{
	public static var INVOTE = 0;
	public static var VALID = 1;
	public static var INVALID = 2;
	public static var OLD = 3;
	//}

	public function new()
	{
		super();

		created = Date.now();
		author = null;
		type = PROJECT;
		status = INVOTE;
		name = "";
		description = "";
		picture = "";
		date = null;
	}

	public static function toObject(instance : Group)
	{
		if(instance == null)
			return null;
		return 
		{
			id : instance.id,
			created : instance.created.getTime(),
			author : User.toObject(instance.author),
			type : instance.type,
			status : instance.status,
			name : instance.name,
			description : instance.description,
			date : instance.date,
			picture : instance.picture,
			userVote : instance.userVote,
			upVotes : instance.upVotes,
			downVotes : instance.downVotes,
			neutralVotes : instance.neutralVotes,
			votesValue : instance.votesValue,
			isUserIn : instance.isUserIn,
			isUserAdmin : instance.isUserAdmin,
			users : GroupUser.toArray(instance.users),
		}
	}

	public static function toArray(array : Iterable<Group>)
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
	@:relation(uid) public var author : Null<User>;
	public var type : Int;//SEnum<GroupType>;
	public var status : Int;//SEnum<GroupStatus>;
	
	public var name : String;
	public var description : String;
	public var date : Null<Date>;
	public var picture : String;

	@:skip public var userVote = 0;
	@:skip public var upVotes = 0;
	@:skip public var downVotes = 0;
	@:skip public var neutralVotes = 0;
	@:skip public var votesValue = 0;

	@:skip public var isUserIn = false;
	@:skip public var isUserAdmin = false;
	@:skip public var users : Array<GroupUser>;
}