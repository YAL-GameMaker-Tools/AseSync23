package tools;
import haxe.CallStack;
import haxe.crypto.Crc32;
import haxe.io.Bytes;
import sys.FileSystem;
import sys.io.File;
import sys.io.FileInput;

/**
 * ...
 * @author YellowAfterlife
 */
class FileTools {
	/*static function compareBackup(path1:String, path2:String) {
		try {
			var b1 = File.getBytes(path1);
			var b2 = File.getBytes(path2);
			if (b1.length != b2.length) return false;
			return b1.compare(b2) == 0;
		} catch (x:Dynamic) {
			Sys.println("An error occurred while comparing files (backup edition): " + x);
			Sys.println(CallStack.toString(CallStack.exceptionStack(true)));
			return false;
		}
	}*/
	//
	static inline var compare_chunkSize = 1024;
	static var compare_bytes1 = Bytes.alloc(compare_chunkSize);
	static var compare_bytes2 = Bytes.alloc(compare_chunkSize);
	public static function compare(path1:String, path2:String) {
		if (!FileSystem.exists(path2)) {
			return !FileSystem.exists(path1);
		} else if (!FileSystem.exists(path1)) return false;
		var size = FileSystem.stat(path1).size;
		if (size != FileSystem.stat(path2).size) return false;
		
		// todo: a better comparison
		var i1:FileInput = null, i2:FileInput = null;
		try {
			i1 = File.read(path1);
			i2 = File.read(path2);
		} catch (x:Dynamic) {
			if (i1 != null) i1.close();
			if (i2 != null) i2.close();
			Sys.println("An error occurred while starting to compare files: " + x);
			Sys.println(CallStack.toString(CallStack.exceptionStack(true)));
			return false;
			Sys.println("Running the backup comparator.");
			//return compareBackup(path1, path2);
		}
		try {
			var b1 = compare_bytes1;
			var b2 = compare_bytes2;
			var left = size;
			while (left > 0) {
				var n1 = i1.readBytes(b1, 0, compare_chunkSize);
				var n2 = i2.readBytes(b2, 0, compare_chunkSize);
				if (n1 != n2) {
					//trace(n1, n2);
					return false;
				}
				if (b1.compare(b2) != 0) return false;
				left -= compare_chunkSize;
			}
		} catch (x:Dynamic) {
			Sys.println('An error occurred while comparing "$path1" to "$path2" (size $size): ' + x);
			Sys.println(CallStack.toString(CallStack.exceptionStack(true)));
		}
		if (i1 != null) i1.close();
		if (i2 != null) i2.close();
		return true;
	}
}