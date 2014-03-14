import haxe.web.Dispatch;
import php.Web;

class Server
{
	var api : Api;
	var result = "";
	var includeTemplate = true;

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
			Dispatch.run(Web.getURI().substring(4), Web.getParams(), this);
		}
		catch(error : DispatchError)
		{
			do404(new Dispatch(Web.getURI().substring(4), Web.getParams()));
		}

		if(Web.getParams().get("template") == "false")
			includeTemplate = false;

		if(includeTemplate)
			Sys.print(new templo.Loader("global.html").execute({content : result, currentUser : api.getCurrentUser()}));
		else
			Sys.print(result);
	}

	public function do404(dispatch : Dispatch)
	{
		trace("Error 404");
	}

	public function doDefault()
	{
		doIndex(new Dispatch(Web.getURI(), Web.getParams()));
	}
	public function doEvents(dispatch : Dispatch)
	{
		var data : Dynamic;
		if(dispatch.parts.length == 0)
			data = {currentUser : api.getCurrentUser(), groups : api.getEvents()};
		else
			data = {currentUser : api.getCurrentUser(), group : api.getEvent(Std.parseInt(dispatch.parts[0]))};

		result = new templo.Loader("events.html").execute(data);
	}
	public function doIndex(dispatch : Dispatch)
	{
		var data = {currentUser : api.getCurrentUser()};
		result = new templo.Loader("index.html").execute(data);
	}
	public function doLogin(dispatch : Dispatch)
	{
		var data = {currentUser : api.getCurrentUser()};
		result = new templo.Loader("login.html").execute(data);
	}
	public function doMessages(dispatch : Dispatch)
	{
		var data = {currentUser : api.getCurrentUser()};
		result = new templo.Loader("messages.html").execute(data);
	}
	public function doPresentation(dispatch : Dispatch)
	{
		var data = {currentUser : api.getCurrentUser()};
		result = new templo.Loader("presentation.html").execute(data);
	}
	public function doProjects(dispatch : Dispatch)
	{
		var data : Dynamic;
		if(dispatch.parts.length == 0)
			data = {currentUser : api.getCurrentUser(), groups : api.getProjects()};
		else
			data = {currentUser : api.getCurrentUser(), group : api.getProject(Std.parseInt(dispatch.parts[0]))};
		result = new templo.Loader("projects.html").execute(data);
	}
	public function doTeams(dispatch : Dispatch)
	{
		var data : Dynamic;
		if(dispatch.parts.length == 0)
			data = {currentUser : api.getCurrentUser(), groups : api.getTeams()};
		else
			data = {currentUser : api.getCurrentUser(), group : api.getTeam(Std.parseInt(dispatch.parts[0]))};

		result = new templo.Loader("teams.html").execute(data);
	}
	public function doUsers(dispatch : Dispatch)
	{
		var data : Dynamic;
		if(dispatch.parts.length == 0)
			data = {currentUser : api.getCurrentUser(), users : api.getUsers()};
		else
			data = {currentUser : api.getCurrentUser(), user : api.getUser(Std.parseInt(dispatch.parts[0]))};

		result = new templo.Loader("users.html").execute(data);
	}
	public function doVotes(dispatch : Dispatch)
	{
		var data = {currentUser : api.getCurrentUser(), users : api.getUsers(), groups : api.getVotes()};
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