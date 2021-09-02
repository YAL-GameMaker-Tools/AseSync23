package tools;
import haxe.crypto.Crc32;
import haxe.io.Bytes;
import sys.FileSystem;
import sys.io.File;

/**
 * ...
 * @author YellowAfterlife
 */
class FileTools {
	public static function compare(path1:String, path2:String) {
		if (!FileSystem.exists(path2)) return false;
		if (FileSystem.stat(path1).size != FileSystem.stat(path2).size) return false;
		
		// todo: a better comparison
		var chunkSize = 256;
		var i1 = File.read(path1);
		var i2 = File.read(path2);
		var b1 = Bytes.alloc(chunkSize);
		var b2 = Bytes.alloc(chunkSize);
		var p = 0;
		try {
			while (!i1.eof()) {
				var n1 = i1.readBytes(b1, 0, chunkSize);
				var n2 = i2.readBytes(b2, 0, chunkSize);
				if (n1 != n2) {
					//trace(n1, n2);
					return false;
				}
				for (i in 0 ... n1) {
					if (b1.get(i) != b2.get(i)) {
						//trace(p + i, b1.get(i), b2.get(i));
						return false;
					}
				}
				p += n1;
				//trace(p);
			}
		} catch (x:Dynamic) {
			//trace(x);
		}
		return true;
	}
}