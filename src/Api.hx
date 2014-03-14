import php.Session;
import sys.io.File;
import data.*;

using StringTools;
using DateTools;

class Api
{
	static var instance : Api;
	static var config : Dynamic;
	private var user : User;

	static function main()
	{
		// Start server
		instance = new Api();
		var context = new haxe.remoting.Context();
		context.addObject("api",instance); 
		haxe.remoting.HttpConnection.handleRequest(context);
	}

	public function new()
	{
		// Start php session
		Session.start();

		// Load config
		config = haxe.Json.parse(File.getContent("../api/config.json"));

		// Load Database
		sys.db.Manager.cnx = sys.db.Mysql.connect(config.database);
		if(!sys.db.TableCreate.exists(User.manager))  { sys.db.TableCreate.create(User.manager);  }
		if(!sys.db.TableCreate.exists(Group.manager)) { sys.db.TableCreate.create(Group.manager); }
		if(!sys.db.TableCreate.exists(Vote.manager)) { sys.db.TableCreate.create(Vote.manager); }
		if(!sys.db.TableCreate.exists(GroupUser.manager)) { sys.db.TableCreate.create(GroupUser.manager); }
		if(!sys.db.TableCreate.exists(Message.manager)) { sys.db.TableCreate.create(Message.manager); }

		if(Session.exists("id"))
		{
			user = User.manager.get(Session.get("id"));
			user.logged = true;
		}
		else
			user = new User();
	}

	/*
	 * Current user functions
	 */

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

	public function getCurrentUser()
	{
		return user;
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

	/*
	 * User functions
	 */

	public function getUser(userId : Int)
	{
		return User.manager.get(userId);
	}

	public function getUsers()
	{
		return User.manager.search($type != User.OLD);
	}

	/*
	 * Group functions
	 */
	
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

	public function editGroup(groupId : Int, name : String, description : String, picture : String)
	{
		var group = Group.manager.get(groupId, true);
		group.name = name;
		group.description = description;
		if(picture != null)
			group.picture = picture;

		group.update();

		return true;
	}

	/*
	 * Vote functions
	 */
	
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

	public function getVotes()
	{

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
		return groups;
	}

	/*
	 * Event functions
	 */

	public function getEvents()
	{
		return Group.manager.search($status == Group.VALID && $type == Group.EVENT);
	}

	public function getEvent(eventId : Int)
	{
		var group = Group.manager.select($id == eventId && $type == Group.EVENT);
		group.users = Lambda.array(GroupUser.manager.search($gid == eventId));
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
		return group;
	}

	/*
	 * Message functions
	 */
	
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

	/*
	 * Project functions
	 */
	
	public function getProjects()
	{
		return Group.manager.search($status == Group.VALID && $type == Group.PROJECT);
	}

	public function getProject(projectId : Int)
	{
		var group = Group.manager.select($id == projectId && $type == Group.PROJECT);
		group.users = Lambda.array(GroupUser.manager.search($gid == projectId));
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
		return group;
	}

	/*
	 * Team functions
	 */
	
	public function getTeams()
	{
		return Group.manager.search($status == Group.VALID && $type == Group.TEAM);
	}

	public function getTeam(teamId : Int)
	{
		var group = Group.manager.select($id == teamId && $type == Group.TEAM);
		group.users = Lambda.array(GroupUser.manager.search($gid == teamId));
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
		return group;
	}

}