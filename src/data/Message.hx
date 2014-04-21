package data;
import sys.db.Types;

@:id(id)
@:table("v4_messages")
class Message extends sys.db.Object
{
	public function new(thread : String, content : String, user : User)
	{
		super();

		this.created = Date.now();
		this.author = user;
		this.thread = thread;
		this.content = content;
	}

	public static function toObject(instance : Message)
	{
		if(instance == null)
			return null;
		return 
		{
			id : instance.id,
			created : instance.created.getTime(),
			author : User.toObject(instance.author),
			thread : instance.thread,
			content : instance.content,
		}
	}

	public static function toArray(array : Iterable<Message>)
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
	@:relation(uid) public var author : User;
	public var thread : String;
	public var content : String;
}