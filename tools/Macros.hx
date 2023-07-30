package tools;

/**
 * ...
 * @author YellowAfterlife
 */
class Macros {
	public static macro function buildDate() {
		var now = Date.now();
		var nows = DateTools.format(now, "%Y-%m-%d");
		return macro $v{nows};
	}
}