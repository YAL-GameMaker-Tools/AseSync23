package tools;

/**
 * ...
 * @author YellowAfterlife
 */
class MySysTools {
	static var getPath_shownNote = false;
	public static function readLine():String {
		#if cs
		return cs.system.Console.ReadLine();
		#else
		return Sys.stdin().readLine();
		#end
	}
	public static function getPath(what:String, ?sub:String) {
		Sys.println('Please enter $what');
		if (sub != null) Sys.println(sub);
		if (!getPath_shownNote) {
			if (Sys.systemName() == "Windows") {
				Sys.println("[you can shift-right-click the file in Explorer and pick 'Copy as path']");
			}
			getPath_shownNote = true;
		}
		Sys.print("> ");
		return readLine();
	}
}