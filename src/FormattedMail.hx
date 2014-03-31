class FormattedMail extends Mail
{
	var title : String;

	public function new(title : String)
	{
		super();
		this.title = title;
	}

	override public function send() : Bool
	{
		content = new templo.Loader("mails/format.html").execute({title : title, content : content});
		return super.send();
	}
}