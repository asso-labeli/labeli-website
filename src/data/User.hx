package data;
import sys.db.Types;

@:id(id)
@:table("v4_users")
class User extends sys.db.Object
{
	//enum UserType
	//{
	public static var VISITOR = 0;
	public static var USER = 1;
	public static var PUBLISHER = 2;
	public static var ADMIN = 3;
	public static var OLD = 4;
	//}

	public function new()
	{
		super();

		username = "";
		email = "";
		firstName = "";
		lastName = "";
		passwordHash = "";
		privateKey = "";
		created = Date.now();
		type = VISITOR;
		universityGroup = "";
		description = "";
		role = "";
		birthday = null;
		logged = false;
		picture = "";
	}

	public static function toObject(instance : User) : {id : Int, created : Float, username : String, firstName : String, lastName : String, email : String, type : Int, universityGroup : String, description : String, role : String, birthday : Float, picture : String, logged : Bool }
	{
		if(instance == null)
			return null;
		return
		{
			id : instance.id,
			created : instance.created.getTime(),
			username : instance.username,
			firstName : instance.firstName,
			lastName : instance.lastName,
			email : instance.email,
			type : instance.type,
			universityGroup : instance.universityGroup,
			description : instance.description,
			role : instance.role,
			birthday : instance.birthday != null ? instance.birthday.getTime() : null,
			picture : instance.picture,
			logged : instance.logged
		}
	}

	public static function toArray(array : Iterable<User>)
	{
		var result = new Array<Dynamic>();
		if(array == null)
			return result;
		for(element in array)
			result.push(toObject(element));
		return result;
	}

	public function isAdmin()
	{
		return type == ADMIN;
	}

	public static function encodePassword(password : String) : String
	{
		return haxe.crypto.Md5.encode(Config.getData().saltStart+password+Config.getData().saltEnd);
	}
	
	public var id : SId;
	public var created : Date;
	@:relation(uid) public var author : Null<User>;
	public var type : Int; //SEnum<UserType>;

	public var username : String;
	public var firstName : String;
	public var lastName : String;
	public var email : String;
	public var passwordHash : String;
	public var privateKey : String;
	public var universityGroup : String;
	public var description : String;
	public var role : String;
	public var birthday : Null<Date>;
	public var picture : String;
	
	@:skip public var logged : Bool;
}