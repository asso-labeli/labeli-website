package data;
import sys.db.Types;

@:id(id)
@:table("v4_surveyVotes")
class SurveyVote extends sys.db.Object
{
	public function new(survey : String, surveyItem : String, user : User)
	{
		super();

		this.created = Date.now();
		this.user = user;
		this.surveyItem = surveyItem;
		this.survey = survey;
	}

	public static function toObject(instance : SurveyVote)
	{
		if(instance == null)
			return null;
		return 
		{
			id : instance.id,
			created : instance.created.getTime(),
			user : User.toObject(instance.user),
			survey : instance.survey,
			surveyItem : instance.surveyItem
		}
	}

	public static function toArray(array : Iterable<SurveyVote>)
	{
		var result = new Array<Dynamic>();
		if(array == null)
			return result;
		for(element in array)
			result.push(toObject(element));
		return result;
	}

	public var id : SId;
	public var created : Date;
	public var survey : String;
	public var surveyItem : String;
	@:relation(uid) public var user : User;
}