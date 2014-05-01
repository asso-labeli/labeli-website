import php.Session;
import sys.io.File;
import data.*;

using StringTools;
using DateTools;

class Api
{
	static var instance : Api;
	private var user : User;

	public function new()
	{
		// Start php session
		Session.start();

		// Load Database
		sys.db.Manager.cnx = sys.db.Mysql.connect(Config.getData().database);
		if(!sys.db.TableCreate.exists(User.manager))  { sys.db.TableCreate.create(User.manager);  }
		if(!sys.db.TableCreate.exists(Group.manager)) { sys.db.TableCreate.create(Group.manager); }
		if(!sys.db.TableCreate.exists(Vote.manager)) { sys.db.TableCreate.create(Vote.manager); }
		if(!sys.db.TableCreate.exists(GroupUser.manager)) { sys.db.TableCreate.create(GroupUser.manager); }
		if(!sys.db.TableCreate.exists(Message.manager)) { sys.db.TableCreate.create(Message.manager); }
		if(!sys.db.TableCreate.exists(SurveyVote.manager)) { sys.db.TableCreate.create(SurveyVote.manager); }

		if(Session.exists("id"))
		{
			user = User.manager.get(Session.get("id"));
			user.logged = true;
		}
		else
		{
			user = new User();
		}
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
			Session.set("id", user.id);
		}
		return User.toObject(newUser);
	}

	public function logout() : Bool
	{
		Session.remove("id");
		return true;
	}

	public function getCurrentUser()
	{
		return User.toObject(user);
	}

	public function createUser(firstName : String, lastName : String, email : String) : Bool
	{
		if(!user.isAdmin())
			throw "You don't have rights to do this";

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

	public function editUser(userId : Int, role : String, universityGroup : String, birthday : Int, description : String, picture : String) : Bool
	{
		if(!user.isAdmin() && userId != getCurrentUser().id)
			throw "You don't have rights to do this";
			
		var user = User.manager.get(userId);
		if(getCurrentUser().type == User.ADMIN)
			user.role = role;
		user.universityGroup = universityGroup;
		user.birthday = Date.fromTime(birthday);
		user.description = description;
		if(picture != null && picture != "")
			user.picture = picture;

		user.update();
		return true;
	}

	/*
	 * User functions
	 */

	public function getUser(userId : Int)
	{
		return User.toObject(User.manager.get(userId));
	}

	public function getUsers()
	{
		return User.toArray(User.manager.search($type != User.OLD, {orderBy : firstName}));
	}

	public function getOldUsers()
	{
		return User.toArray(User.manager.search($type == User.OLD, {orderBy : firstName}));
	}

	/*
	 * Group functions
	 */
	
	public function createGroup(name : String, userId : Int, type : String) : Bool
	{
		if(!user.isAdmin())
			throw "You don't have rights to do this";

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
		if(!user.logged)
			throw "You don't have rights to do this";
		GroupUser.manager.select($gid == groupId && $user == user).delete();
		return true;
	}

	public function joinGroup(groupId : Int) : Bool
	{
		if(!user.logged)
			throw "You don't have rights to do this";
		if(GroupUser.manager.select($gid == groupId && $user == user) == null)
			new GroupUser(Group.manager.get(groupId), user, "Membre", false).insert();
		return true;
	}

	public function editGroup(groupId : Int, name : String, description : String, picture : String)
	{
		var group = Group.manager.get(groupId, true);

		if(!user.isAdmin() && group.author.id != getCurrentUser().id)
			throw "You don't have rights to do this";

		group.name = name;
		group.description = description;
		if(picture != null)
			group.picture = picture;

		group.update();

		return true;
	}

	public function validateGroup(groupId : Int) : Bool
	{
		if(!user.isAdmin())
			throw "You don't have rights to do this";

		var group = Group.manager.get(groupId);
		group.status = Group.VALID;
		group.update();
		return true;
	}

	public function unvalidateGroup(groupId : Int) : Bool
	{
		if(!user.isAdmin())
			throw "You don't have rights to do this";

		var group = Group.manager.get(groupId);
		group.status = Group.INVOTE;
		group.update();
		return true;
	}

	public function deleteGroup(groupId : Int) : Bool
	{
		if(!user.isAdmin())
			throw "You don't have rights to do this";

		var group = Group.manager.get(groupId);
		group.delete();
		return true;
	}

	public function addUserToGroup(groupId : Int, userId : Int, label : String) : Bool
	{
		if(!user.isAdmin() && userId != getCurrentUser().id)
			throw "You don't have rights to do this";

		if(GroupUser.manager.select($gid == groupId && $uid == userId) == null)
			new GroupUser(Group.manager.get(groupId), User.manager.get(userId), label, false).insert();
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
		var groups = Group.manager.search($status == Group.INVOTE, {orderBy : -created});
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
		return Group.toArray(groups);
	}

	/*
	 * Event functions
	 */

	public function getEvents()
	{
		return Group.toArray(Group.manager.search($status == Group.VALID && $type == Group.EVENT));
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
		return Group.toObject(group);
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
		return Message.toArray(Message.manager.search($thread == thread && $created > Date.fromTime(since), {orderBy : created}));
	}

	/*
	 * Project functions
	 */
	
	public function getProjects()
	{
		return Group.toArray(Group.manager.search($status == Group.VALID && $type == Group.PROJECT));
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
		return Group.toObject(group);
	}

	/*
	 * Team functions
	 */
	
	public function getTeams()
	{
		return Group.toArray(Group.manager.search($status == Group.VALID && $type == Group.TEAM));
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
		return Group.toObject(group);
	}

	public function getSurveyData(surveyName : String)
	{
		var votes = SurveyVote.manager.search($survey == surveyName);

		var itemsName = new Array<String>();
		var userIds = new Array<Int>();
		var itemsVotes = new Array<Int>();
		var userVotes = new Array<Bool>();
		var itemsCount = 0;
		var totalVotes = 0;

		for(vote in votes)
		{
			if(!Lambda.has(itemsName, vote.surveyItem))
				itemsName.push(vote.surveyItem);
			if(!Lambda.has(userIds, vote.user.id))
				userIds.push(vote.user.id);
		}
		
		itemsCount = itemsName.length;
		totalVotes = userIds.length;

		for(i in 0...itemsCount)
		{
			itemsVotes[i] = 0;
			userVotes[i] = false;
		}
		for(vote in votes)
		{
			if(vote.user == user)
				userVotes[Lambda.indexOf(itemsName, vote.surveyItem)] = true;
			itemsVotes[Lambda.indexOf(itemsName, vote.surveyItem)] += 1;
		}

		return {itemsCount : itemsCount, totalVotes : totalVotes, itemsName : itemsName, itemsVotes : itemsVotes, userVotes : userVotes, }
	}

	public function voteForSurvey(surveyName : String, surveyItem : String, value : Bool)
	{
		if(!user.logged)
			throw "You don't have rights to do this";

		if(value)
		{
			if(SurveyVote.manager.select($survey == surveyName && $surveyItem == surveyItem && $user == user) == null)
				new SurveyVote(surveyName, surveyItem, user).insert();
		}
		else
		{
			var surveyVote = SurveyVote.manager.select($user == user && $survey == surveyName && $surveyItem == surveyItem);
			if(surveyVote != null)
				surveyVote.delete();
		}


		return true;
	}

	public function sendMail(title : String, content : String, recipientId : Int, preformat : Bool, sendAsAdmin : Bool) : Bool
	{
		if(!user.logged)
			throw "You don't have rights to do this";

		var mail : Mail = (preformat && user.isAdmin()) ? new FormattedMail(title) : new Mail();
				
		if(sendAsAdmin && user.isAdmin())
		{
			mail.subject = "Label[i] - "+title;
			mail.sender = {name : "Label[i]", email : "contact@labeli.org"};
		}
		else
		{
			mail.subject = title;
			mail.sender = {name : user.firstName+" "+user.lastName, email : user.email};
		}

		mail.content = content;

		if(recipientId == 0)
		{
			if(user.isAdmin())
			{
				var users = User.manager.search($type != User.OLD, {orderBy : firstName});
				for(recipient in users)
					mail.recipients.push({name : recipient.firstName+" "+recipient.lastName, email : recipient.email});
			}
		}
		else if(recipientId == -1)
		{
			var bureau = User.manager.search($type == User.ADMIN);
			for(recipient in bureau)
				mail.recipients.push({name : recipient.firstName+" "+recipient.lastName, email : recipient.email});
		}
		else
		{
			var recipient = User.manager.get(recipientId);
			if(recipient == null)
				throw "can't find recipient with id "+recipientId;
			mail.recipients.push({name : recipient.firstName+" "+recipient.lastName, email : recipient.email});
		}

		return mail.send();
	}

	public function previewMail(title : String, content : String, preformat : Bool) : Bool
	{
		var mailContent = content;
		if(preformat && user.isAdmin())
			mailContent = new templo.Loader("mails/format.html").execute({title : title, content : content});
		sys.FileSystem.createDirectory("files");
		sys.io.File.saveContent("files/newsletter.html", mailContent);
		return true;
	}

	public function isHouseOpened() : Bool
	{
		return sys.FileSystem.exists(".houseOpened");
	}

	public function setHouseOpened(opened : Bool) : Bool
	{
		if(!user.isAdmin())
			throw "You don't have rights to do this";

		if(opened)
			sys.io.File.saveContent(".houseOpened", "house is opened");
		else
			sys.FileSystem.deleteFile(".houseOpened");

		return true;
	}
}