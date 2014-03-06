package data;
import sys.db.Types;

@:id(id)
@:table("next_groups")
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
		date = null;
	}

	public function getObject()
	{
		return 
		{
			id : this.id,
			created : this.created,
			author : this.author,
			type : this.type,
			status : this.status,
			name : this.name,
			description : this.description,
			date : this.date,
		}
	}

	public function getTypeString() : String
	{
		if (type == TEAM)
			return "team";
		if (type == EVENT)
			return "event";
		return "project";
	}


	public var id : SId;
	public var created : Date;
	@:relation(uid) public var author : Null<User>;
	public var type : Int;//SEnum<GroupType>;
	public var status : Int;//SEnum<GroupStatus>;
	
	public var name : String;
	public var description : String;
	public var date : Null<Date>;

	@:skip public var userVote = 0;
	@:skip public var upVotes = 0;
	@:skip public var downVotes = 0;
	@:skip public var neutralVotes = 0;
	@:skip public var votesValue = 0;

	@:skip public var isUserIn = false;
	@:skip public var isUserAdmin = false;
	@:skip public var users : Array<GroupUser>;
}