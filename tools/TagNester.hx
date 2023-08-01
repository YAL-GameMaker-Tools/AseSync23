package tools;
import AseData;

/**
 * ...
 * @author YellowAfterlife
 */
class TagNester {
	static function makeIdent(s:String) {
		s = StringTools.replace(s, " ", "_");
		s = ~/[^\w]/g.replace(s, "");
		return s;
	}
	public static function concat(a:String, b:String) {
		a = makeIdent(a);
		b = makeIdent(b);
		if (a == "") return b;
		if (b == "") return a;
		return a + "_" + b;
	}
	public static function proc(frame_tags:Array<AseDataTag>) {
		var new_frame_tags = [];
		var total_length = frame_tags.length;
		for (i in 0 ... total_length) {
			var tag = frame_tags[i];
			
			//if any subsequent tags are within this tags range.
			//then the current tags name gets prepended to their names
			//the current tag gets discared from the new array
			
			var is_parent = false;
			var lookahead = 1;
			
			if(i+lookahead < total_length){
				var tag_ahead = frame_tags[i+lookahead];
			
				while(tag.from <= tag_ahead.from && tag.to >= tag_ahead.to ){
					is_parent = true;
					
					if(tag.parent != null){
						tag_ahead.parent = concat(tag_ahead.parent, tag.name);
					} else {
						tag_ahead.parent = tag.name;
					}
					
					lookahead++;
					if(i+lookahead < total_length){
						tag_ahead = frame_tags[i+lookahead];
					} else break;
				}
			}
			
			if(is_parent == false) {    
				new_frame_tags.push(tag);
			}
		}
		
		//combines the name and parent name together
		for (i in 0 ... new_frame_tags.length) {
			var tag = new_frame_tags[i];
			if (tag.parent != null) {
				tag.name = concat(tag.parent, tag.name);
				Reflect.deleteField(tag, "parent");
			}
		}
		return new_frame_tags;
	}
}