package ;
import haxe.DynamicAccess;

/**
 * Aseprite's --data format
 * @author YellowAfterlife
 */
typedef AseData = {
	frames:DynamicAccess<{
		frame:{
			x:Int,
			y:Int,
			w:Int,
			h:Int
		},
		rotated:Bool,
		trimmed:Bool,
		spriteSourceSize:{
			x:Int,
			y:Int,
			w:Int,
			h:Int
		},
		sourceSize:{
			w:Int,
			h:Int
		},
		duration:Int
	}>,
	meta:AseDataMeta,
};
typedef AseDataMeta = {
	app:String,
	version:String,
	format:String,
	size:{
		w:Int,
		h:Int
	},
	?frameTags:Array<AseDataTag>,
	scale:String
};
typedef AseDataTag = {
	name:String,
	from:Int,
	to:Int,
	direction:String,
	color:String,
	// non-standard
	?parent:String,
};