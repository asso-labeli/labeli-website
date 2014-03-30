import haxe.macro.Context;

class Config
{
	public macro static function getData()
	{
		var config = haxe.Json.parse(sys.io.File.getContent("src/config.json"));
		return Context.makeExpr(config, Context.currentPos());
    }
}