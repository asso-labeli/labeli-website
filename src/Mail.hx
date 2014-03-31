class Mail
{
	public var recipients : Array<{name : String, email : String}>;
	public var subject : String;
	public var content : String;
	public var sender : Dynamic;

	public function new()
	{
		recipients = new Array();
		subject = "";
		content = "";
	}

	public function send() : Bool
	{
		var headers = new Array<String>();
		if(sender != null)
		{
			headers.push("From:"+encode(sender.name)+"<"+sender.email+">");
			headers.push("Reply-To:"+encode(sender.name)+"<"+sender.email+">");
		}
		headers.push("Content-type: text/html; charset=UTF-8");

		var finalRecipient = "";
		if(recipients.length == 0)
			return false;
		else if(recipients.length == 1)
			finalRecipient = encode(recipients[0].name)+"<"+recipients[0].email+">";
		else
		{
			for(recipient in recipients)
				headers.push("Bcc: "+encode(recipient.name)+"<"+recipient.email+">");
			finalRecipient = encode("Contact - Label[i]")+"<contact@labeli.org>";
		}

		if(headers.length > 0)
			return php.Lib.mail(finalRecipient, encode(subject), content, headers.join("\r\n"));
		return php.Lib.mail(finalRecipient, encode(subject), content);
	}

	private static var BASE64CHARS = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

	private static function fillNullbits( s : String ) : String
	{
		var remainder = s.length % 4;
		if (remainder > 1)
			s += "=";
		if (remainder == 2)
			s += "=";
		return s;
	}

	private static inline function encode( t : String ) : String
	{
		return "=?UTF-8?B?"+fillNullbits( haxe.crypto.BaseCode.encode( t, BASE64CHARS ) )+"?=";
	}
}