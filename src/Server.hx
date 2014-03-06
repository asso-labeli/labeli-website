import php.Session;
import sys.io.File;
import data.*;

using StringTools;
using DateTools;

class Server
{
	static var instance : Server;
	static var config : Dynamic;

	private var user : User;

	static function main()
	{
		// Start php session
		Session.start();

		// Load config
		config = haxe.Json.parse(File.getContent("config.json"));

		// Load Database
		sys.db.Manager.cnx = sys.db.Mysql.connect(config.database);
		if(!sys.db.TableCreate.exists(User.manager))  { sys.db.TableCreate.create(User.manager);  }
		if(!sys.db.TableCreate.exists(Group.manager)) { sys.db.TableCreate.create(Group.manager); }
		if(!sys.db.TableCreate.exists(Vote.manager)) { sys.db.TableCreate.create(Vote.manager); }
		if(!sys.db.TableCreate.exists(GroupUser.manager)) { sys.db.TableCreate.create(GroupUser.manager); }
		if(!sys.db.TableCreate.exists(Message.manager)) { sys.db.TableCreate.create(Message.manager); }

		// Load templates
		templo.Loader.BASE_DIR = "templates";
		templo.Loader.TMP_DIR = "templates/";
		templo.Loader.MACROS = null;
		templo.Loader.OPTIMIZED = true;

		// Start server
		instance = new Server();
		var context = new haxe.remoting.Context();
		context.addObject("api",instance); 
		haxe.remoting.HttpConnection.handleRequest(context);
	}

	public function new()
	{
		if(Session.exists("id"))
		{
			user = User.manager.get(Session.get("id"));
			user.logged = true;
		}
		else
			user = new User();
	}

	public function login(username : String, password : String) : Dynamic
	{
		var newUser = User.manager.select($username == username && $passwordHash == User.encodePassword(password));
		
		if(newUser == null)
			return null;
		else
		{
			user = newUser;
			user.logged = true;
		}

		Session.set("id", user.id);

		return
		{
			firstName : user.firstName,
			lastName : user.lastName,
			id : user.id,
			picture : user.picture
		};
	}

	public function logout() : Bool
	{
		Session.remove("id");
		return true;
	}

	public function createUser(firstName : String, lastName : String, email : String) : Bool
	{
		if(user.isAdmin())
		{
			var newUser = new User();
			newUser.firstName = firstName;
			newUser.lastName = lastName;
			newUser.email = email;

			var password = "";
				for(i in 0...16)
					password += String.fromCharCode(65+Std.random(90-65));

			newUser.username = new String(newUser.firstName+"."+newUser.lastName).toLowerCase();
			newUser.created = Date.now();
			newUser.author = user;
			newUser.passwordHash = User.encodePassword(password);
			newUser.type = User.USER;
			newUser.role = "Membre";
			newUser.insert();

			var mail = new mail.FormattedMail("Bienvenue !");
			mail.sender = {name : "Contact - Label[i]", email : "contact@labeli.org"};
			mail.recipients.push({name : newUser.firstName+" "+newUser.lastName, email : newUser.email});
			mail.subject = "Label[i] - Bienvenue";
			mail.content = new templo.Loader("mails/register.html").execute({username : newUser.username, password : password});
			return mail.send();
		}
		return false;
	}

	public function createGroup(name : String, userId : Int, type : String) : Bool
	{
		var newGroup = new Group();
		newGroup.author = User.manager.get(userId);
		newGroup.type = switch(type)
		{
			case "team" : Group.TEAM;
			case "event" : Group.EVENT;
			default : Group.PROJECT;
		};
		newGroup.status = Group.INVOTE;
		newGroup.name = name;
		newGroup.description = "";
		newGroup.date = null;
		newGroup.insert();

		new GroupUser(newGroup, newGroup.author, "Créateur", true).insert();

		return true;
	}

	public function submitVote(groupId : Int, value : Int)
	{
		if(value != -1 && value != 0 && value != 1)
			return false;

		var group = Group.manager.get(groupId);

		var vote = Vote.manager.select($user == user && $group == group, true);
		if(vote == null)
			new Vote(group, user, value).insert();
		else
		{
			vote.value = value;
			vote.update();
		}
		return true;
	}

	public function leaveGroup(groupId : Int) : Bool
	{
		GroupUser.manager.select($gid == groupId && $user == user).delete();
		return true;
	}

	public function joinGroup(groupId : Int) : Bool
	{
		new GroupUser(Group.manager.get(groupId), user, "Membre", false).insert();
		return true;
	}

	public function editGroup(groupId : Int, name : String, description : String, imageData : String)
	{
		var group = Group.manager.get(groupId, true);
		group.name = name;
		group.description = description;
		group.update();

		if(imageData != "")
		{
			sys.io.File.saveBytes("test.png", haxe.io.Bytes.ofString(haxe.crypto.BaseCode.decode(imageData, "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/")));
		}

		return true;
	}

	public function addMessage(thread : String, message : String) : Bool
	{
		new Message(thread, message, user).insert();
		return true;
	}

	public function getMessages(thread : String, since : Float)
	{
		var result = new Array<Dynamic>();
		for(message in Message.manager.search($thread == thread && $created > Date.fromTime(since), {orderBy : created}))
			result.push(message.getObject());
		return result;
	}

	public function getPage(url : String) : String
	{
		if(url == "")
			url = "index";
		var parts = url.split("/");
		var parameters = parts.splice(1, parts.length-1);
		return new templo.Loader(parts[0]+".html").execute(getPageParameters(parts[0], parameters));
	}

	private function getPageParameters(url : String, parameters : Array<String>) : Dynamic
	{
		switch(url)
		{
			case "users" : 
				if(parameters.length == 0)
					return {currentUsers : User.manager.search($type != User.OLD), oldUsers : User.manager.search($type == User.OLD), user : user};
				else
					return {selectedUser : User.manager.get(Std.parseInt(parameters[0])), user : user};
			
			case "teams" : 
				if(parameters.length == 0)
					return {groups : Group.manager.search($status == Group.VALID && $type == Group.TEAM), user : user};
				else
				{
					var groupId = Std.parseInt(parameters[0]);
					var group = Group.manager.select($id == groupId && $type == Group.TEAM);
					group.users = Lambda.array(GroupUser.manager.search($gid == groupId));
					group.isUserIn = false;
					group.isUserAdmin = false;
					for(groupUser in group.users)
					{
						if(groupUser.user == user)
						{
							group.isUserIn = true;
							group.isUserAdmin = groupUser.admin;
						}
					}
					return {group : group, user : user};
				}

			case "events" : 
				if(parameters.length == 0)
					return {groups : Group.manager.search($status == Group.VALID && $type == Group.EVENT), user : user};
				else
				{
					var groupId = Std.parseInt(parameters[0]);
					var group = Group.manager.select($id == groupId && $type == Group.EVENT);
					group.users = Lambda.array(GroupUser.manager.search($gid == groupId));
					group.isUserIn = false;
					group.isUserAdmin = false;
					for(groupUser in group.users)
					{
						if(groupUser.user == user)
						{
							group.isUserIn = true;
							group.isUserAdmin = groupUser.admin;
						}
					}
					return {group : group, user : user};
				}

			case "projects" : 
				if(parameters.length == 0)
					return {groups : Group.manager.search($status == Group.VALID && $type == Group.PROJECT), user : user};
				else
				{
					var groupId = Std.parseInt(parameters[0]);
					var group = Group.manager.select($id == groupId && $type == Group.PROJECT);
					group.users = Lambda.array(GroupUser.manager.search($gid == groupId));
					group.isUserIn = false;
					group.isUserAdmin = false;
					for(groupUser in group.users)
					{
						if(groupUser.user == user)
						{
							group.isUserIn = true;
							group.isUserAdmin = groupUser.admin;
						}
					}
					return {group : group, user : user};
				}
					
			case "messages" : return {formData : {recipients : "all", selectedUser : 1, title : "", content : "", format : true, global : true}, users : User.manager.search($type != User.OLD), user : user};
		
			case "votes" :
				var groups = Group.manager.search($status == Group.INVOTE);
				for(group in groups)
				{
					group.userVote = 0;
					group.upVotes = 0;
					group.neutralVotes = 0;
					group.downVotes = 0;
					var votes = Vote.manager.search($group == group);
					for(vote in votes)
					{
						if(vote.user == user)
							group.userVote = vote.value;
						if(vote.value == 1)
							group.upVotes++;
						else if(vote.value == 0)
							group.neutralVotes++;
						else if(vote.value == -1)
							group.downVotes++;
					}
					group.votesValue = group.upVotes - group.downVotes;
				}
				return {users : User.manager.search($type != User.OLD), groups : groups, user : user};
		}
		return {user : user}
	}
}