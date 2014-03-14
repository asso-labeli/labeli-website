import jQuery.*;

using StringTools;
using DateTools;

class Client
{
	private var subdomain = "/www/";
	private var context : haxe.remoting.HttpAsyncConnection;

	private var anchorsInHistory = 1;
	private var user : Dynamic;

	static function main()
	{
		new Client();
	}

	public function new()
	{
		new JQuery(function()
		{
			context = haxe.remoting.HttpAsyncConnection.urlConnect("http://localhost/api/index.php");
			context.setErrorHandler(onError);
			
			if(js.Browser.getSessionStorage().getItem("user") != null)
			{
				user = haxe.Json.parse(js.Browser.getSessionStorage().getItem("user"));
				switchToUserInterface();
			}

			js.Browser.window.onpopstate = function(event)
			{
				if(anchorsInHistory > 0)
					anchorsInHistory--;
				else
					loadURL(js.Browser.location.pathname.substring(subdomain.length));
			};

			makeLinks();
		});
	}

	public function onError(exception : Dynamic)
	{
		new JQuery("#errors").append(exception);
	}

	public function makeLinks()
	{
		new JQuery("#navUser").next().hide();
		new JQuery("a").off("click").on("click", linkCallback);
		new JQuery("#login-form").off("submit").on("submit", loginCallback);
		new JQuery("#logout-link").off("submit").on("click", logoutCallback);
		new JQuery("#navUser").off("click").on("click", function(){new JQuery("#navUser").next().toggle();});
		new JQuery("#createUser-form").off("submit").on("submit", createUserCallback);
		new JQuery("#createGroup-form").off("submit").on("submit", createGroupCallback);
	
		new JQuery(".vote").find(".button.up").off("click").on("click", voteCallback);
		new JQuery(".vote").find(".button.neutral").off("click").on("click", voteCallback);
		new JQuery(".vote").find(".button.down").off("click").on("click", voteCallback);

		new JQuery("#leaveGroupLink").off("click").on("click", leaveGroupCallback);
		new JQuery("#joinGroupLink").off("click").on("click", joinGroupCallback);
		new JQuery("#editGroupLink").off("click").on("click", editGroupCallback);

		new JQuery("#editUser").off("click").on("click", editUserCallback);
/*
		var chatBox = new JQuery(".chatBox");
		var messageTime = 0;
		if(chatBox.length > 0)
		{
			function refresh()
			{
				context.api.getMessages.call([chatBox.attr("href"), messageTime], function(result : Array<Dynamic>)
				{
					if(result.length == 0)
					{
						if(messageTime == 0)
							chatBox.find(".messages").html("<section class=\"center\">Aucun message</section>");
					}
					else
					{
						for(message in result)
						{
							chatBox.find(".messages").append("<div class=\"chatMessage\">
							<div class=\"author\" style=\"background : url('"+message.author.picture+"-33x33.png') no-repeat;\">"+message.author.firstName+" "+message.author.lastName+" le "+Date.fromTime(message.created).format("%e/%m/%C à %R")+"</div>
							<div class=\"content\">"+message.content+"</div>
						</div>");
							messageTime = message.created;
						}
						var amountToBeScroll = Std.parseInt(chatBox.find(".messages").prop("scrollHeight"));
						chatBox.find(".messages").scrollTop(amountToBeScroll);
					}
				});
			}
			//js.Browser.window.setInterval(refresh, 1000);


			chatBox.find("form").off("submit").on("submit", function(event : Event)
			{
				event.preventDefault();
				context.api.addMessage.call([chatBox.attr("href"), chatBox.find("input[type=\"text\"]").val()], function(result : Bool)
				{
					chatBox.find("input[type=\"text\"]").val("");
				});
			});
		}
		*/
/*
		<div class="chatBox" href="::group.getTypeString()::/::group.id::">
				<div class="messages">
					<!-- <div class="chatMessage">
						<div class="author" style="background : url('::user.picture::-33x33.png') no-repeat;">Alix le 31/12/9999</div>
						<div class="content">Lorem ipsum dolor sit amet, consectetur adipisicing elit. Aperiam, dolorem optio consectetur expedita</div>
					</div>-->
				</div>
				::if user.logged::
					<form class="inline sendMessage">
						<input type="text" placeholder="Envoyer un message" />
						<input type="submit" value="Envoyer" />
					</form>
				::end::
			</div>*/
	}

	public function linkCallback(event : Event)
	{
		var link = new JQuery(event.target).closest("a").attr("href");
		if(!link.startsWith("#"))
		{
			event.preventDefault();
			loadURL(link);
		}
		else
		{
			anchorsInHistory += 2;
		}
	}

	public function loginCallback(event : Event)
	{
		event.preventDefault();
		var form : js.html.Element = cast event.target;
		var usernameInput : js.html.InputElement = cast (new JQuery(form).find("input[type=\"text\"]")[0]);
		var passwordInput : js.html.InputElement = cast (new JQuery(form).find("input[type=\"password\"]")[0]);
		
		context.api.login.call([usernameInput.value, passwordInput.value], function(result : Dynamic)
		{
			if(result != null)
			{
				user = result;
				js.Browser.getSessionStorage().setItem("user", haxe.Json.stringify(user));
				switchToUserInterface();
				loadURL("");
			}
			else
				new JQuery("form").after("<div class=\"message error\">Les identifiants sont incorrects.</div>").next().delay(3000).fadeOut(250);
		});
	}

	public function switchToUserInterface()
	{
		new JQuery("#navUser").show();
		new JQuery("#navUser").html(user.firstName+" ↓");
		new JQuery(".additionalLinks a:first-child").attr("href", "users/"+user.id);
		new JQuery("#navUser").css("background-image", "url('"+user.picture+"-33x33.png')");
		new JQuery("#loginLink").hide();
	}

	public function logoutCallback(event : Event)
	{
		event.preventDefault();
		
		context.api.logout.call([], function(result : Bool)
		{
			if(result)
			{
				loadURL("");
				js.Browser.getSessionStorage().removeItem("user");
				new JQuery("#loginLink").show();
				new JQuery("#navUser").hide();
				new JQuery("#navUser").next().hide();
			}
		});
	}

	public function createUserCallback(event : Event)
	{
		event.preventDefault();
		var form : js.html.Element = cast event.target;
		var firstNameInput : js.html.InputElement = cast (new JQuery(form).find("input[name=\"firstName\"]")[0]);
		var lastNameInput : js.html.InputElement = cast (new JQuery(form).find("input[name=\"lastName\"]")[0]);
		var emailInput : js.html.InputElement = cast (new JQuery(form).find("input[name=\"email\"]")[0]);
		
		context.api.createUser.call([firstNameInput.value, lastNameInput.value, emailInput.value], function(result : Bool)
		{
			if(result)
				reloadURL();
			else
				new JQuery("form").after("<div class=\"message error\">Nope.</div>").next().delay(3000).fadeOut(250);
		});
	}

	public function createGroupCallback(event : Event)
	{
		event.preventDefault();
		var form : js.html.Element = cast event.target;
		var nameInput : js.html.InputElement = cast (new JQuery(form).find("input[name=\"name\"]")[0]);
		var authorInput : String = cast (new JQuery(form).find("select[name=\"author\"]").val());
		var typeInput : String = cast (new JQuery(form).find("select[name=\"type\"]").val());

		context.api.createGroup.call([nameInput.value, authorInput, typeInput], function(result : Bool)
		{
			if(result)
				reloadURL();
			else
				new JQuery("form").after("<div class=\"message error\">Nope.</div>").next().delay(3000).fadeOut(250);
		});
	}

	public function voteCallback(event : Event)
	{
		event.preventDefault();
		var href = new JQuery(event.target).closest(".vote").find(".infos").find("a").attr("href");
		var groupId = Std.parseInt(href.substring(href.lastIndexOf("/")+1));
		
		var value : Null<Int> = null;
		if(new JQuery(event.target).hasClass("up"))
			value = 1;
		if(new JQuery(event.target).hasClass("down"))
			value = -1;
		if(new JQuery(event.target).hasClass("neutral"))
			value = 0;

		context.api.submitVote.call([groupId, value], function(result : Bool)
		{
			if(result)
			{
				switch(value)
				{
					case 1 :
						new JQuery(event.target).closest(".vote").find(".up").removeClass("active").addClass("active");
						new JQuery(event.target).closest(".vote").find(".neutral").removeClass("active");
						new JQuery(event.target).closest(".vote").find(".down").removeClass("active");
					case -1 :
						new JQuery(event.target).closest(".vote").find(".up").removeClass("active");
						new JQuery(event.target).closest(".vote").find(".neutral").removeClass("active");
						new JQuery(event.target).closest(".vote").find(".down").removeClass("active").addClass("active");
					case 0 :
						new JQuery(event.target).closest(".vote").find(".up").removeClass("active");
						new JQuery(event.target).closest(".vote").find(".neutral").removeClass("active").addClass("active");
						new JQuery(event.target).closest(".vote").find(".down").removeClass("active");
					default :
					
				}
			}
		});
	}

	public function leaveGroupCallback(event : Event)
	{
		context.api.leaveGroup.call([Std.parseInt(js.Browser.document.location.pathname.split("/")[3])], function(result : Bool)
		{
			if(result)
				reloadURL();
		});
	}

	public function joinGroupCallback(event : Event)
	{
		context.api.joinGroup.call([Std.parseInt(js.Browser.document.location.pathname.split("/")[3])], function(result : Bool)
		{
			if(result)
				reloadURL();
		});
	}

	public function editGroupCallback(event : Event)
	{
		function editGroup(groupId : Int, name : String, description : String, picture : String)
		{
			context.api.editGroup.call([groupId, name, description, picture], function(result : Bool)
			{
				if(result)
				{
					new JQuery("#submitChanges").remove();
					new JQuery("#resetChanges").remove();
					new JQuery("#editGroupLink").show();
					new JQuery("section.group").find("h1").attr("contenteditable", "false").css("min-height", "initial");
					new JQuery("section.group").find(".description").attr("contenteditable", "false").css("min-height", "initial");
					new JQuery("section.group").find(".description").html(new JQuery("section.group").find(".description").html().htmlUnescape());
					new JQuery("#uploadImage").remove();
					if(picture != null)
						new JQuery(".group").css("background-image", "url(/www/"+picture+")");
				}
			});
		}

		function submitChanges(groupId : Int)
		{
			return function(event : js.html.Event)
			{
				var input : js.html.InputElement = cast new JQuery("section.group").find("input")[0];
				if(input.files.length == 1)
				{
					uploadFile(input, function(result : JqXHR)
					{
						editGroup(groupId, new JQuery("section.group").find("h1").html(), new JQuery("section.group").find(".description").html().htmlUnescape(), result.responseText);
					});	
				}
				else
				{
					editGroup(groupId, new JQuery("section.group").find("h1").html(), new JQuery("section.group").find(".description").html().htmlUnescape(), null);
				}
			}
		}

		function resetChanges(title : String, description : String)
		{
			return function(event : js.html.Event)
			{
				new JQuery("#submitChanges").remove();
				new JQuery("#resetChanges").remove();
				new JQuery("#editGroupLink").show();

				new JQuery("section.group").find("h1").html(title);
				new JQuery("section.group").find(".description").html(description.htmlUnescape());

				new JQuery("section.group").find("h1").attr("contenteditable", "false").css("min-height", "initial");
				new JQuery("section.group").find(".description").attr("contenteditable", "false").css("min-height", "initial");
				new JQuery("#uploadImage").remove();
			}
		}

		// Retrieve group id
		var groupId = Std.parseInt(js.Browser.document.location.pathname.split("/")[3]);
		
		// Set title and description to be editable and add a form to upload picture
		new JQuery("section.group").find("h1").css("min-height", ""+(new JQuery("section.group").find("h1").height()-2)+"px");
		new JQuery("section.group").find("h1").attr("contenteditable", "true");
		new JQuery("section.group").find(".description").css("min-height", ""+(new JQuery("section.group").find(".description").height()-2)+"px");
		new JQuery("section.group").find(".description").attr("contenteditable", "true");
		new JQuery("section.group").find(".description").html(new JQuery("section.group").find(".description").html().htmlEscape());
		new JQuery("section.group").append("<form id=\"uploadImage\" enctype=\"multipart/form-data\"><input type=\"file\" class=\"groupPicture\" /></form>");

		// Backup values
		var title = new JQuery("section.group").find("h1").html();
		var description = new JQuery("section.group").find(".description").html();

		// Hide edit button and show submit and cancel buttons
		new JQuery(event.target).hide();
		new JQuery(event.target).after("<a class=\"button\" id=\"submitChanges\">Valider les modifications</a>");
		new JQuery("#submitChanges").on("click", submitChanges(groupId));
		new JQuery("#submitChanges").after("<a class=\"button\" id=\"resetChanges\">Annuler les modifications</a>");
		new JQuery("#resetChanges").on("click", resetChanges(title, description));
	}

	public function editUserCallback(event : Event)
	{
		function editUser(userId : Int, role : String, universityGroup : String, birthday : Int, description : String, picture : String)
		{
			context.api.editUser.call([userId, role, universityGroup, birthday, description, picture], function(result : Bool)
			{
				if(result)
				{
					new JQuery("#submitChanges").remove();
					new JQuery("#resetChanges").remove();
					new JQuery("#editUser").show();

					new JQuery("section.user").find(".universityGroup .value").attr("contenteditable", "false").css("min-height", "initial");
					new JQuery("section.user").find(".role .value").attr("contenteditable", "false").css("min-height", "initial");
					new JQuery("section.user").find(".birthday .value").attr("contenteditable", "false").css("min-height", "initial");
					new JQuery("section.user").find(".description").html(new JQuery("section.user").find(".description").html().htmlUnescape());
					new JQuery("#uploadImage").remove();
					if(picture != null)
						new JQuery("section.user").css("background-image", "url(/www/"+picture+")");
				}
			});
		}

		function submitChanges(userId : Int)
		{
			return function(event : js.html.Event)
			{
				var input : js.html.InputElement = cast new JQuery("section.user").find("input")[0];
				if(input.files.length == 1)
				{
					uploadFile(input, function(result : JqXHR)
					{
						editUser(userId,
							new JQuery("section.user").find(".role .value").html(),
							new JQuery("section.user").find(".universityGroup .value").html(),
							Std.parseInt(new JQuery("section.user").find(".birthday .value").html()),
							new JQuery("section.user").find(".description").html().htmlUnescape(),
							result.responseText);
					});	
				}
				else
				{
					editUser(userId,
						new JQuery("section.user").find(".role .value").html(),
						new JQuery("section.user").find(".universityGroup .value").html(),
						Std.parseInt(new JQuery("section.user").find(".birthday .value").html()),
						new JQuery("section.user").find(".description").html().htmlUnescape(),
						null);
				}
			}
		}

		function resetChanges(role : String, universityGroup : String, birthday : String, description : String)
		{
			return function(event : js.html.Event)
			{
				new JQuery("#submitChanges").remove();
				new JQuery("#resetChanges").remove();
				new JQuery("#editUser").show();

				new JQuery("section.user").find(".role .value").html(role).attr("contenteditable", "false").css("min-height", "initial");
				new JQuery("section.user").find(".universityGroup .value").html(universityGroup).attr("contenteditable", "false").css("min-height", "initial");
				new JQuery("section.user").find(".birthday .value").html(birthday).attr("contenteditable", "false").css("min-height", "initial");
				new JQuery("section.user").find(".description").html(description.htmlUnescape()).attr("contenteditable", "false").css("min-height", "initial");

				new JQuery("#uploadImage").remove();
			}
		}

		// Retrieve user id
		var userId = Std.parseInt(js.Browser.document.location.pathname.split("/")[3]);
		
		// Set title and description to be editable and add a form to upload picture
		new JQuery("section.user").find(".role .value").css("min-height", ""+(new JQuery("section.user").find(".role .value").height()-2)+"px");
		new JQuery("section.user").find(".role .value").attr("contenteditable", "true");
		new JQuery("section.user").find(".universityGroup .value").css("min-height", ""+(new JQuery("section.user").find(".universityGroup .value").height()-2)+"px");
		new JQuery("section.user").find(".universityGroup .value").attr("contenteditable", "true");
		new JQuery("section.user").find(".birthday .value").css("min-height", ""+(new JQuery("section.user").find(".birthday .value").height()-2)+"px");
		new JQuery("section.user").find(".birthday .value").attr("contenteditable", "true");
		new JQuery("section.user").find(".description").css("min-height", ""+(new JQuery("section.user").find(".description").height()-2)+"px");
		new JQuery("section.user").find(".description").attr("contenteditable", "true");
		new JQuery("section.user").find(".description").html(new JQuery("section.user").find(".description").html().htmlEscape());
		new JQuery("section.user").append("<form id=\"uploadImage\" enctype=\"multipart/form-data\"><input type=\"file\" class=\"userPicture\" /></form>");

		// Backup values
		var role = new JQuery("section.user").find(".role .value").html();
		var universityGroup = new JQuery("section.user").find(".universityGroup .value").html();
		var birthday = new JQuery("section.user").find(".birthday .value").html();
		var description = new JQuery("section.user").find(".description").html();

		// Hide edit button and show submit and cancel buttons
		new JQuery(event.target).hide();
		new JQuery(event.target).after("<a class=\"button\" id=\"submitChanges\">Valider les modifications</a>");
		new JQuery("#submitChanges").on("click", submitChanges(userId));
		new JQuery("#submitChanges").after("<a class=\"button\" id=\"resetChanges\">Annuler les modifications</a>");
		new JQuery("#resetChanges").on("click", resetChanges(role, universityGroup, birthday, description));
	}

	public function loadURL(url : String)
	{
		new JQuery("#content").hide();
		new JQuery("#loading").animate({opacity : 1}, 250);

		js.Browser.window.history.pushState({}, "Label[i]", subdomain+url);
		JQueryStatic.ajax(
			{
				url : subdomain+url+"?template=false",
				success : function(result : String)
				{
					new JQuery("#loading").animate({opacity : 0}, 250);
					new JQuery("#content").html(result);
					new JQuery("#content").show();
					makeLinks();
				}
			}
		);
	}

	private function reloadURL()
	{
		loadURL(js.Browser.document.location.pathname.substring(subdomain.length));		
	}

	public function uploadFile(input : js.html.InputElement, callback : JqXHR -> Void)
	{
		var formData = new js.html.DOMFormData();
		untyped __js__("formData.append(\"file\", input.files[0]);");

		JQueryStatic.ajax({
			url: subdomain+'upload',
			type: 'POST',
			data: formData,
			complete : callback,
			cache: false,
			contentType: false,
			processData: false
		});
	}
}