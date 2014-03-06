package data;
import sys.db.Types;

@:id(id)
@:table("next_messages")
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

	public function getObject()
	{
		return 
		{
			id : this.id,
			created : this.created.getTime(),
			author : this.author.getObject(),
			thread : this.thread,
			content : this.content,
		}
	}

	public var id : SId;
	public var created : Date;
	@:relation(uid) public var author : User;
	public var thread : String;
	public var content : String;
}