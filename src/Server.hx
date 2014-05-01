import haxe.web.Dispatch;
import php.Web;

class ServerTools
{
	public function new()
	{
	}

	public function getTypeString(group : Dynamic) : String
	{
		if (group.type == 1)
			return "team";
		if (group.type == 2)
			return "event";
		return "project";
	}

	public function getPictureOrDefault(group : Dynamic, defaultValue : String) : String
	{
		return group.picture == "" ? defaultValue : group.picture;
	}

	public function isAdmin(user : Dynamic) : Bool
	{
		return user.type == 3;
	}

	public function formatTimestamp(timestamp : Int, format : String) : String
	{
		var date = Date.fromTime(timestamp);
		return DateTools.format(date, format);
	}

	public function getRoot()
	{
		return Config.getData().root;
	}
}

class Server
{
	var api : Api;
	var result = "";
	var includeTemplate = true;
	var tools = new ServerTools();

	static function main()
	{
		templo.Loader.BASE_DIR = "templates";
		templo.Loader.TMP_DIR = "templates/";
		templo.Loader.MACROS = null;
		templo.Loader.OPTIMIZED = true;
	
		var server = new Server();
	}

	public function new()
	{
		api = new Api();

		try
		{
			Dispatch.run(Web.getURI().substring(tools.getRoot().length), Web.getParams(), this);
		}
		catch(error : DispatchError)
		{
			do404(new Dispatch(Web.getURI().substring(tools.getRoot().length), Web.getParams()));
		}

		if(Web.getParams().get("template") == "false")
			includeTemplate = false;

		if(includeTemplate)
			Sys.print(new templo.Loader("global.html").execute({content : result, currentUser : api.getCurrentUser(), tools : tools}));
		else
			Sys.print(result);
	}

	public function doApi(dispatch : Dispatch)
	{
		var context = new haxe.remoting.Context();
		context.addObject("api", api);
		if(haxe.remoting.HttpConnection.handleRequest(context))
		{
			includeTemplate = false;
			return;
		}
    
    	var apiMethods = new Array<{name : String}>();
    	for(field in Type.getInstanceFields(Api))
		{
			apiMethods.push({name : field});

			/*var data = haxe.rtti.Meta.getFields(Type.getClass(this));
			try
			{
				var meta = Reflect.field(data, field);
				for(metadata in Reflect.fields(meta))
					Sys.print("<div class=\""+metadata+"\">"+Reflect.field(meta, metadata)[0]+"</div>");
			}
			catch(e : String)
			{
			}*/
		}

		var data = {tools : tools, apiMethods : apiMethods};
		result = new templo.Loader("api.html").execute(data);
	}

	public function do404(dispatch : Dispatch)
	{
		trace("Error 404 : "+dispatch.parts);
	}

	public function doDefault()
	{
		doIndex(new Dispatch(Web.getURI(), Web.getParams()));
	}
	public function doEvents(dispatch : Dispatch)
	{
		var data : Dynamic;
		if(dispatch.parts.length == 0)
			data = {tools : tools, currentUser : api.getCurrentUser(), groups : api.getEvents()};
		else
			data = {tools : tools, currentUser : api.getCurrentUser(), group : api.getEvent(Std.parseInt(dispatch.parts[0])), users : api.getUsers()};

		result = new templo.Loader("events.html").execute(data);
	}
	public function doIndex(dispatch : Dispatch)
	{
		var data = {tools : tools, currentUser : api.getCurrentUser(), projects : api.getProjects(), events : api.getEvents(), houseOpened : api.isHouseOpened()};
		result = new templo.Loader("index.html").execute(data);
	}
	public function doLogin(dispatch : Dispatch)
	{
		var data = {tools : tools, currentUser : api.getCurrentUser()};
		result = new templo.Loader("login.html").execute(data);
	}
	public function doMessages(dispatch : Dispatch)
	{
		var data = {tools : tools, currentUser : api.getCurrentUser(), users : api.getUsers()};
		result = new templo.Loader("messages.html").execute(data);
	}
	public function doPresentation(dispatch : Dispatch)
	{
		var data = {tools : tools, currentUser : api.getCurrentUser()};
		result = new templo.Loader("presentation.html").execute(data);
	}
	public function doProjects(dispatch : Dispatch)
	{
		var data : Dynamic;
		if(dispatch.parts.length == 0)
			data = {tools : tools, currentUser : api.getCurrentUser(), groups : api.getProjects()};
		else
			data = {tools : tools, currentUser : api.getCurrentUser(), group : api.getProject(Std.parseInt(dispatch.parts[0])), users : api.getUsers()};
		result = new templo.Loader("projects.html").execute(data);
	}
	public function doTeams(dispatch : Dispatch)
	{
		var data : Dynamic;
		if(dispatch.parts.length == 0)
			data = {tools : tools, currentUser : api.getCurrentUser(), groups : api.getTeams()};
		else
			data = {tools : tools, currentUser : api.getCurrentUser(), group : api.getTeam(Std.parseInt(dispatch.parts[0])), users : api.getUsers()};

		result = new templo.Loader("teams.html").execute(data);
	}
	public function doUsers(dispatch : Dispatch)
	{
		var data : Dynamic;
		if(dispatch.parts.length == 0)
			data = {tools : tools, currentUser : api.getCurrentUser(), users : api.getUsers(), oldUsers : api.getOldUsers()};
		else
			data = {tools : tools, currentUser : api.getCurrentUser(), user : api.getUser(Std.parseInt(dispatch.parts[0]))};

		result = new templo.Loader("users.html").execute(data);
	}
	public function doVotes(dispatch : Dispatch)
	{
		var data = {tools : tools, currentUser : api.getCurrentUser(), users : api.getUsers(), groups : api.getVotes()};
		result = new templo.Loader("votes.html").execute(data);
	}
	public function doStyle(dispatch : Dispatch)
	{
		includeTemplate = false;
		Resources.get("style/"+dispatch.parts.join("/"), true);
	}
	public function doScripts(dispatch : Dispatch)
	{
		includeTemplate = false;
		Resources.get("scripts/"+dispatch.parts.join("/"), true);
	}
	public function doImages(dispatch : Dispatch)
	{
		includeTemplate = false;
		Resources.get("images/"+dispatch.parts.join("/"), true);
	}
	public function doFiles(dispatch : Dispatch)
	{
		includeTemplate = false;
		Resources.get("files/"+dispatch.parts.join("/"), true);
	}

	public function doUpload(dispatch : Dispatch)
	{
		includeTemplate = false;

		var filename : String = "";
		var fieldname : String = "";
		var file : sys.io.FileOutput = null;
		var upload = false;
		var currentFileName : String = null;
		Web.parseMultipart
		(
			function(pn:String, fn:String)
			{
				fieldname = pn;
				filename = fn;
			},
			function (d:haxe.io.Bytes, pos:Int, len:Int)
			{
				if (fieldname == "file")
				{
					if (currentFileName != filename)
					{
						currentFileName = filename;
						sys.FileSystem.createDirectory("files/"+api.getCurrentUser().id);
						file = sys.io.File.write("files/"+api.getCurrentUser().id+"/"+filename, true);
						file.write(d);
						upload = true;
					}
					else
						file.write(d);
				}
			}
		);

		Sys.print("files/"+api.getCurrentUser().id+"/"+filename);
	}
}