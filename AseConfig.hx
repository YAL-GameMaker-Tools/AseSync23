package ;
import haxe.Json;
import sys.FileSystem;
import sys.io.File;

/**
 * ...
 * @author YellowAfterlife
 */
class AseConfig {
	public static var path:String;
	public static var current:AseConfigData = null;
	
	public static function load() {
		current = {};
		if (!FileSystem.exists(path)) return;
		
		var jsonStr = try {
			File.getContent(path);
		} catch (x:Dynamic) {
			Sys.println('Error reading "$path": $x');
			return;
		}
		
		try {
			current = Json.parse(jsonStr);
		} catch (x:Dynamic) {
			Sys.println('Error parsing configuration: $x');
		}
	}
	public static function save() {
		try {
			File.saveContent(path, Json.stringify(current, null, "\t"));
		} catch (x:Dynamic) {
			Sys.println('Error saving config: $x');
		}
	}
	public static function init() {
		path = AseSync.executableDir + "/config.json";
		load();
	}
}
typedef AseConfigData = {
	?asepritePath:String,
	?lastProjectPath:String,
	?lastWatchPath:String,
	?consent:Bool,
}