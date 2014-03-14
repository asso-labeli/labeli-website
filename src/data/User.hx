package data;
import sys.db.Types;

@:id(id)
@:table("next_users")
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
		created = Date.now();
		type = VISITOR;
		universityGroup = "";
		description = "";
		role = "";
		birthday = null;
		logged = false;
		picture = "";
	}

	public function getObject()
	{
		return {
			id : this.id,
			username : this.username,
			email : this.email,
			firstName : this.firstName,
			lastName : this.lastName,
			passwordHash : this.passwordHash,
			created : this.created,
			type : this.type,
			universityGroup : this.universityGroup,
			description : this.description,
			role : this.role,
			birthday : this.birthday,
			picture : this.picture
		}
	}

	public function isAdmin()
	{
		return type == ADMIN;
	}

	public static function encodePassword(password : String) : String
	{
		return password;
	}

	public function getPictureOrDefault(defaultValue : String)
	{
		return picture == "" ? defaultValue : picture;
	}
	
	public var id : SId;
	public var created : Date;
	@:relation(uid) public var author : Null<User>;
	public var type : Int; //SEnum<UserType>;

	public var email : String;
	public var username : String;
	public var firstName : String;
	public var lastName : String;
	public var passwordHash : String;
	public var universityGroup : String;
	public var description : String;
	public var role : String;
	public var birthday : Null<Date>;
	public var picture : String;
	
	@:skip public var logged : Bool;
}