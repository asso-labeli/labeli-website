import jQuery.*;

using StringTools;
using DateTools;

class Client
{
	private var root = Config.getData().root;
	private var context : haxe.remoting.HttpAsyncConnection;
	private var syncContext : haxe.remoting.HttpConnection;

	private var anchorsInHistory = 1;
	private var user : Dynamic;
	private var chatboxRefreshId : Null<Int> = null;

	static function main()
	{
		new Client();
	}

	public function new()
	{
		//trace(js.Browser.document.location.pathname.substring(root.length).split("/"));
		new JQuery(function()
		{
			context = haxe.remoting.HttpAsyncConnection.urlConnect(root+"api");
			context.setErrorHandler(onError);
			syncContext = haxe.remoting.HttpConnection.urlConnect(root+"api");
			
			autoLogin();
			initHistory();
			makeLinks();
		});
	}

	public function onError(exception : Dynamic)
	{
		trace(exception);
	}

	public function autoLogin()
	{
		user = syncContext.api.getCurrentUser.call([]);
		if(user.id != null)
		{
			switchToUserInterface();
		}
	}

	public function initHistory()
	{
		js.Browser.window.onpopstate = function(event)
		{
			if(anchorsInHistory > 0)
				anchorsInHistory--;
			else
				loadURL(js.Browser.location.pathname.substring(root.length));
		};
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
		new JQuery("#addUserToGroup").off("click").on("click", addUserToGroupCallback);
		new JQuery("#validateGroupLink").off("click").on("click", validateGroupCallback);
		new JQuery("#unvalidateGroupLink").off("click").on("click", unvalidateGroupCallback);
		new JQuery("#deleteGroupLink").off("click").on("click", deleteGroupCallback);

		new JQuery("#editUser").off("click").on("click", editUserCallback);

		new JQuery("#mailSend").off("click").on("click", sendMailCallback);
		new JQuery("#mailPreview").off("click").on("click", previewMailCallback);
		new JQuery("#mailPreviewSection").hide();
		new JQuery("#closeHouse").off("click").on("click", closeHouseCallback);
		new JQuery("#openHouse").off("click").on("click", openHouseCallback);


		var chatBox = new JQuery(".chatBox");
		var messageTime = 0;
		if(chatboxRefreshId != null)
		{
			js.Browser.window.clearInterval(chatboxRefreshId);
			chatboxRefreshId = null;
		}
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
							<div class=\"author\" style=\"background : url('/"+message.author.picture+"') no-repeat; background-size : 33px 33px;\">"+message.author.firstName+" "+message.author.lastName+" le "+Date.fromTime(message.created).format("%e/%m/%C à %R")+"</div>
							<div class=\"content\">"+message.content+"</div>
						</div>");
							messageTime = message.created;
						}
						var amountToBeScroll = Std.parseInt(chatBox.find(".messages").prop("scrollHeight"));
						chatBox.find(".messages").scrollTop(amountToBeScroll);
					}
				});
			}
			chatboxRefreshId = js.Browser.window.setInterval(refresh, 1000);

			chatBox.find("form").off("submit").on("submit", function(event : Event)
			{
				event.preventDefault();
				context.api.addMessage.call([chatBox.attr("href"), chatBox.find("input[type=\"text\"]").val()], function(result : Bool)
				{
					chatBox.find("input[type=\"text\"]").val("");
				});
			});
		}


		var surveys = new JQuery(".survey");
		var widgets = new JQuery("#widgets");
		surveys.each(function(i : Int, element : js.html.Node)
		{
			var surveyName = new JQuery(element).attr("name");
			var voteItems = new Array<String>();
			new JQuery(element).find("label").each(function(i2 : Int, element2 : js.html.Node) { voteItems.push(new JQuery(element2).html()); });

			context.api.getSurveyData.call([surveyName], function(result : Dynamic)
			{
				widgets.append("<table class=\"surveyWidget\" name=\""+surveyName+"\"></table>");
				var surveyHTML = widgets.last();
				for(item in voteItems)
				{
					var index = Lambda.indexOf(result.itemsName, item);

					surveyHTML.append("<tr class=\"vote\">"+
						(user.id != null ? "<td><input id=\"surveyItem-"+item+"\" type=\"checkbox\" name=\""+item+"\"" + (result.userVotes[index] ? "checked=\"true\"" : "") + "\" /></td>" : "")+
						"<td><label for=\"surveyItem-"+item+"\">"+item+"</label></td>
						<td><progress value=\""+(result.itemsVotes[index] == null ? 0 : result.itemsVotes[index])+"\" max=\""+result.totalVotes+"\"></progress></td>
						</tr>");

					if(user.id != null)
					{
						var checkbox = surveyHTML.last().last().find("input[type=\"checkbox\"]");
						checkbox.off("click").on("click", function(event : Event)
						{
							var checkbox = new JQuery(event.target); 
							var checked = checkbox.is(':checked');
							context.api.voteForSurvey.call([surveyName, checkbox.attr("name"), checked], function(result : Bool)
							{
								checkbox.attr("checked", Std.string(checked));
								/*label.next().attr("value", Std.parseInt(label.next().attr("value")) + (if(checked) 1 else -1));
								if(Std.parseInt(label.next().attr("value")) > Std.parseInt(label.next().attr("max")))
								{
									label.parent().find("progress").attr("max", Std.parseInt(label.next().attr("max"))+1);
								}*/
							});
						});
					}
				}
				
				/*
				survey.find("label").each(function(i2 : Int, element2 : js.html.Node)
				{
					var label = new JQuery(element2);
					label.prev().off("click").on("click", function(event : Event)
					{
					});
				});
				*/
			});
		});
	}

	public function linkCallback(event : Event)
	{
		var link = new JQuery(event.target).closest("a").attr("href").substring(root.length);
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
		
		context.api.login.call([usernameInput.value, passwordInput.value], function(loggedUser : Dynamic)
		{
			user = loggedUser;
			if(user != null && user.id != null)
			{
				switchToUserInterface();
				loadURL("index");
			}
			else
				new JQuery("form").after("<div class=\"message error\">Les identifiants sont incorrects.</div>").next().delay(3000).fadeOut(250);
		});
	}

	public function switchToUserInterface()
	{
		new JQuery("#navUser").show();
		new JQuery("#navUser").html(user.firstName+" ↓");
		new JQuery(".additionalLinks a:first-child").attr("href", root+"users/"+user.id);
		new JQuery("#navUser").css("background-image", "url('"+root+user.picture+"')");
		new JQuery("#loginLink").hide();
	}

	public function logoutCallback(event : Event)
	{
		event.preventDefault();
		
		if(syncContext.api.logout.call([]))
		{
			loadURL("index");
			new JQuery("#loginLink").show();
			new JQuery("#navUser").hide();
			new JQuery("#navUser").next().hide();
		}
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
		context.api.leaveGroup.call([Std.parseInt(js.Browser.document.location.pathname.substring(root.length).split("/")[1])], function(result : Bool)
		{
			if(result)
				reloadURL();
		});
	}

	public function joinGroupCallback(event : Event)
	{
		context.api.joinGroup.call([Std.parseInt(js.Browser.document.location.pathname.substring(root.length).split("/")[1])], function(result : Bool)
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
					new JQuery("section.group").find(".description").replaceWith("<div class=\"description\">"+description+"</div>");
					new JQuery("#uploadImage").remove();
					if(picture != null)
						new JQuery(".group").css("background-image", "url("+root+picture+")");
				}
			});
		}

		function submitChanges(groupId : Int)
		{
			return function(event : js.html.Event)
			{
				var input : js.html.InputElement = cast new JQuery("section.group").find("input[type=file]")[0];
				if(input.files.length == 1)
				{
					uploadFile(input, function(result : JqXHR)
					{
						editGroup(groupId, new JQuery("section.group").find("h1").html(), new JQuery("section.group").find(".description").val(), result.responseText);
					});	
				}
				else
				{
					editGroup(groupId, new JQuery("section.group").find("h1").html(), new JQuery("section.group").find(".description").val(), null);
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
				new JQuery("section.group").find("h1").attr("contenteditable", "false").css("min-height", "initial");

				new JQuery("section.group").find(".description").replaceWith("<div class=\"description\">"+description+"</div>");

				new JQuery("#uploadImage").remove();
			}
		}

		// Retrieve group id
		var groupId = Std.parseInt(js.Browser.document.location.pathname.substring(root.length).split("/")[1]);
		
		// Set title and description to be editable and add a form to upload picture
		new JQuery("section.group").find("h1").css("min-height", ""+(new JQuery("section.group").find("h1").height()-2)+"px");
		new JQuery("section.group").find("h1").attr("contenteditable", "true");
		new JQuery("section.group").find(".description").replaceWith("<textarea class=\"description\">"+new JQuery("section.group").find(".description").html()+"</textarea>");
/*		new JQuery("section.group").find(".description").css("min-height", ""+(new JQuery("section.group").find(".description").height()-2)+"px");
*/		new JQuery("section.group").append("<form id=\"uploadImage\" enctype=\"multipart/form-data\"><input type=\"file\" class=\"groupPicture\" /></form>");

		// Backup values
		var title = new JQuery("section.group").find("h1").html();
		var description = new JQuery("section.group").find(".description").val();

		// Hide edit button and show submit and cancel buttons
		new JQuery(event.target).hide();
		new JQuery(event.target).after("<a class=\"button\" id=\"submitChanges\">Valider les modifications</a>");
		new JQuery("#submitChanges").on("click", submitChanges(groupId));
		new JQuery("#submitChanges").after("<a class=\"button\" id=\"resetChanges\">Annuler les modifications</a>");
		new JQuery("#resetChanges").on("click", resetChanges(title, description));
	}

	public function addUserToGroupCallback(event : Event)
	{
		event.preventDefault();
		var groupId = Std.parseInt(js.Browser.document.location.pathname.substring(root.length).split("/")[1]);
		context.api.addUserToGroup.call([groupId, new JQuery("#newUserId").val(), new JQuery("#newUserLabel").val()], function(result : Bool)
		{
			if(result)
			{
				trace("ok");
			}
		});
	}

	public function validateGroupCallback(event : Event)
	{
		// Retrieve group id
		var groupId = Std.parseInt(js.Browser.document.location.pathname.substring(root.length).split("/")[1]);

		context.api.validateGroup.call([groupId], function(result : Bool)
		{
			if(result)
			{
				new JQuery("#validateGroupLink").replaceWith("<a class=\"button\" id=\"unvalidateGroupLink\">Revoter ce projet</a>");
				new JQuery("#unvalidateGroupLink").off("click").on("click", unvalidateGroupCallback);
			}
		});
	}

	public function unvalidateGroupCallback(event : Event)
	{
		// Retrieve group id
		var groupId = Std.parseInt(js.Browser.document.location.pathname.substring(root.length).split("/")[1]);

		context.api.unvalidateGroup.call([groupId], function(result : Bool)
		{
			if(result)
			{
				new JQuery("#unvalidateGroupLink").replaceWith("<a class=\"button\" id=\"validateGroupLink\">Valider ce projet</a>");
				new JQuery("#validateGroupLink").off("click").on("click", validateGroupCallback);
			}
		});
	}

	public function deleteGroupCallback(event : Event)
	{
		// Retrieve group id
		var groupId = Std.parseInt(js.Browser.document.location.pathname.substring(root.length).split("/")[1]);
		context.api.deleteGroup.call([groupId], function(result : Bool) {});
		loadURL(js.Browser.document.location.pathname.split("/")[1]);
	}

	public function editUserCallback(event : Event)
	{
		var admin = false;
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
					new JQuery("section.user").find(".description").replaceWith("<div class=\"description\">"+description+"</div>");
					new JQuery("#uploadImage").remove();
					if(picture != null)
						new JQuery("section.user").css("background-image", "url("+root+picture+")");
				}
			});
		}

		function submitChanges(userId : Int)
		{
			return function(event : js.html.Event)
			{
				var input : js.html.InputElement = cast new JQuery("section.user").find("input[type=\"file\"]")[0];

				var dateValue = new JQuery("section.user").find(".birthday .value").html();
				var dateParts = dateValue.split("/");
				var birthdayTime : Int = cast new Date(Std.parseInt(dateParts[2]), Std.parseInt(dateParts[1])-1, Std.parseInt(dateParts[0]),1,0,0).getTime();

				if(input.files.length == 1)
				{
					uploadFile(input, function(result : JqXHR)
					{
						editUser(userId,
							new JQuery("section.user").find(".role .value").html(),
							new JQuery("section.user").find(".universityGroup .value").html(),
							Std.parseInt(new JQuery("section.user").find(".birthday .value").html()),
							new JQuery("section.user").find(".description").val(),
							result.responseText);
					});	
				}
				else
				{
					editUser(userId,
						new JQuery("section.user").find(".role .value").html(),
						new JQuery("section.user").find(".universityGroup .value").html(),
						birthdayTime,
						new JQuery("section.user").find(".description").val(),
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

				if(admin)
					new JQuery("section.user").find(".role .value").html(role).attr("contenteditable", "false").css("min-height", "initial");
				new JQuery("section.user").find(".universityGroup .value").html(universityGroup).attr("contenteditable", "false").css("min-height", "initial");
				new JQuery("section.user").find(".birthday .value").html(birthday).attr("contenteditable", "false").css("min-height", "initial");
				new JQuery("section.user").find(".description").replaceWith("<div class=\"description\">"+description+"</div>");

				new JQuery("#uploadImage").remove();
			}
		}

		// Retrieve user id
		var userId = Std.parseInt(js.Browser.document.location.pathname.substring(root.length).split("/")[1]);
		
		// Set title and description to be editable and add a form to upload picture
		if(admin)
		{
			new JQuery("section.user").find(".role .value").css("min-height", ""+(new JQuery("section.user").find(".role .value").height()-2)+"px");
			new JQuery("section.user").find(".role .value").attr("contenteditable", "true");
		}
		new JQuery("section.user").find(".universityGroup .value").css("min-height", ""+(new JQuery("section.user").find(".universityGroup .value").height()-2)+"px");
		new JQuery("section.user").find(".universityGroup .value").attr("contenteditable", "true");
		new JQuery("section.user").find(".birthday .value").css("min-height", ""+(new JQuery("section.user").find(".birthday .value").height()-2)+"px");
		new JQuery("section.user").find(".birthday .value").attr("contenteditable", "true");

		new JQuery("section.user").find(".description").replaceWith("<textarea class=\"description\">"+new JQuery("section.user").find(".description").html()+"</textarea>");

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
		url = root+url;
		new JQuery("#content").hide();
		new JQuery("#loading").animate({opacity : 1}, 250);

		js.Browser.window.history.pushState({}, "Label[i]", url);
		JQueryStatic.ajax(
			{
				url : url+"?template=false",
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
		trace(js.Browser.document.location.pathname);
		loadURL(js.Browser.document.location.pathname);
	}

	public function uploadFile(input : js.html.InputElement, callback : JqXHR -> Void)
	{
		var formData = new js.html.DOMFormData();
		untyped __js__("formData.append(\"file\", input.files[0]);");

		JQueryStatic.ajax({
			url: root+"upload",
			type: "POST",
			data: formData,
			complete : callback,
			cache: false,
			contentType: false,
			processData: false
		});
	}

	public function sendMailCallback(event : Event)
	{
		event.preventDefault();
		var content = new JQuery("#mailContent").val();
		var title = new JQuery("#mailTitle").val();
		var sendAsAdmin = new JQuery("#mailSendAsAdmin").is(':checked');
		var preformat = new JQuery("#mailPreformat").is(':checked');
		var recipientId = switch(new JQuery("input[name=\"recipient\"]:checked").val())
		{
			case "bureau" : -1;
			case "all" : 0;
			case "user" : Std.parseInt(new JQuery("#mailRecipientUser").val());
			default : throw "Undefined recipient";
		};

		context.api.sendMail.call([title, content, recipientId, preformat, sendAsAdmin], function(result : Bool)
		{
			trace(result);
		});

	}

	public function previewMailCallback(event : Event)
	{
		event.preventDefault();
		var content = new JQuery("#mailContent").val();
		var title = new JQuery("#mailTitle").val();
		var sendAsAdmin = new JQuery("#mailSendAsAdmin").is(':checked');
		var preformat = new JQuery("#mailPreformat").is(':checked');
		var recipientId = switch(new JQuery("input[name=\"recipient\"]:checked").val())
		{
			case "bureau" : -1;
			case "all" : 0;
			case "user" : Std.parseInt(new JQuery("#mailRecipientUser").val());
			default : throw "Undefined recipient";
		};

		context.api.previewMail.call([title, content, preformat], function(result : Bool)
		{
			if(result)
			{
				new JQuery("#mailPreviewSection").show();
				var iframe : js.html.IFrameElement = cast(new JQuery("#mailPreviewSection iframe").get(0));
				iframe.contentDocument.location.reload();
			}
		});
	}

	public function closeHouseCallback(event : Event)
	{
		syncContext.api.setHouseOpened.call([false]);
		reloadURL();
	}

	public function openHouseCallback(event : Event)
	{
		syncContext.api.setHouseOpened.call([true]);
		reloadURL();
	}
}