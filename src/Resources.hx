import php.Web;
import haxe.web.Dispatch;
import sys.io.File;

using StringTools;

class Resources
{
	public static function get(filename : String, cache : Bool)
	{
		var path = filename;

		var parts = path.split(".");
		var mimeType = getMimeType(parts[parts.length-1]);
		Web.setHeader("Content-Type", mimeType);
		Web.setHeader("Cache-Control", "public, max-age=31536000");
		Web.setHeader("Expires", dateToRfc(DateTools.delta(Date.now(), 31536000000)));
		Web.setHeader("Last-Modified", dateToRfc(sys.FileSystem.stat(path).mtime));

		if(Web.getClientHeader("If-Modified-Since") != null && cache && (Date.fromString(Web.getClientHeader("If-Modified-Since")).getTime() > sys.FileSystem.stat(path).mtime.getTime()))
			Web.setReturnCode(304);
		else
			Sys.print(File.getContent(path));
	}

	private static function parseHeaderDate(dateString : String)
	{
	}

	public static function getMimeType(extension : String) : String
	{
		return switch(extension)
		{
		case "html"	: "text/html";
		case "htm"	: "text/html";
		case "js"	: "text/javascript";
		case "png"	: "image/png";
		case "jpg"	: "image/jpeg";
		case "css"	: "text/css";
		case "svg"	: "image/svg+xml";
		case "ttf"	: "application/x-font-ttf";
		case "otf"	: "application/x-font-opentype";
		case "woff"	: "application/font-woff";
		case "eot"	: "application/vnd.ms-fontobject";
		case "ogg"	: "audio/ogg";
		default		: "application/octet-stream";
		}
	}

	public static function rfcToDate(str : String) : Date
	{
		// Sun, 06 Nov 1994 08:49:37 GMT
		var parts = str.split(" ");
		var time = parts[4].split(":");

		var month = switch(parts[2])
		{
		case "Jan" : 0;
		case "Feb" : 1;
		case "Mar" : 2;
		case "Apr" : 3;
		case "May" : 4;
		case "Jun" : 5;
		case "Jul" : 6;
		case "Aug" : 7;
		case "Sep" : 8;
		case "Oct" : 9;
		case "Nov" : 10;
		case "Dec" : 11;
		default : 0;
		}
		return new Date(Std.parseInt(parts[3]), month, Std.parseInt(parts[1]), Std.parseInt(time[0]), Std.parseInt(time[1]), Std.parseInt(time[2]));
	}

	public static function dateToRfc(date : Date) : String
	{
		var str = "";
		str += switch(date.getDay())
		{
		case 0 : "Mon";
		case 1 : "Tue";
		case 2 : "Wed";
		case 3 : "Thu";
		case 4 : "Fri";
		case 5 : "Sat";
		case 6 : "Sun";
		default : "";
		}
		str += ", "+date.getDate()+" ";
		str += switch(date.getMonth())
		{
		case 0 : "Jan";
		case 1 : "Feb";
		case 2 : "Mar";
		case 3 : "Apr";
		case 4 : "May";
		case 5 : "Jun";
		case 6 : "Jul";
		case 7 : "Aug";
		case 8 : "Sep";
		case 9 : "Oct";
		case 10 : "Nov";
		case 11 : "Dec";
		default : "";
		}
		str += " ";
		str += date.getFullYear();
		str += " ";
		str += date.getHours() < 10 ? "0"+date.getHours() : ""+date.getHours();
		str += ":";
		str += date.getMinutes() < 10 ? "0"+date.getMinutes() : ""+date.getMinutes();
		str += ":";
		str += date.getSeconds() < 10 ? "0"+date.getSeconds() : ""+date.getSeconds();
		str += " GMT";
		return str;
	}
}