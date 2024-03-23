import haxe.CallStack;
import tools.MySysTools;
import haxe.io.Path;
import sys.FileSystem;
import sys.io.File;
import sys.thread.Mutex;
import yy.*;
#if cs
import cs.system.io.FileSystemWatcher;
import cs.system.io.NotifyFilters;
import cs.system.io.FileSystemEventArgs;
#else
import hx.concurrent.executor.Executor;
import hx.files.watcher.PollingFileWatcher;
#end

class AseSync {
	public static var executableDir:String;
	
	public static var projectPath:String;
	public static var projectDir:String;
	public static var projectData:YyProject = null;
	public static var watchDir:String;
	public static var asepritePath:String = null;
	public static var prefix:String = "Sprites";
	public static var epsilon:Float = 0.05;
	
	public static var baseSpriteName:String = "spr_asebase";
	public static var baseSpriteText:String;
	public static var baseSpriteFrameText:String;
	public static var baseSpriteKeyFrameText:String;
	public static var baseSpritePath:String;
	public static function syncBaseSprite(?text:String, ?yySpr:YySprite) {
		var sprText = text ?? File.getContent(baseSpritePath);
		var baseSpriteData:YySprite = yySpr ?? YyJson.parse(sprText);
		baseSpriteFrameText = YyJson.stringify(baseSpriteData.frames[0]);
		trace(yySpr.name, yySpr);
		baseSpriteKeyFrameText = YyJson.stringify(baseSpriteData.sequence.tracks[0].keyframes.Keyframes[0]);
		baseSpriteText = sprText;
	}
	
	public static inline var maxOrder = 9999;
	
	static var resourceNameRx:EReg = ~/^\w+$/;
	public static function isAse(path:String) {
		var pt = new Path(path);
		if (!resourceNameRx.match(pt.file)) return false;
		if (pt.ext == null) return false;
		return switch (pt.ext.toLowerCase()) {
			case "ase", "aseprite": true;
			default: false;
		}
	}
	
	static function flushYyp() {
		if (projectData == null) return;
		File.saveContent(projectPath, YyJson.stringify(projectData));
		projectData = null;
	}
	
	static function initMeta() {
		YyJsonMeta.fieldType["GMProject"] = [
			"configs" => "GMConfig"
		];
		YyJsonMeta.fieldType["GMConfig"] = [
			"children" => "GMConfig[]"
		];
		YyJsonMeta.fieldOrder["GMConfig"] = ["name", "children"];
	}
	static var checkMtx:Mutex = new Mutex();
	static var checkNext:Array<String> = [];
	#if cs
	static function fwcListener(sender:Any, e:FileSystemEventArgs) {
		var path = Path.normalize(e.FullPath);
		checkMtx.acquire();
		checkNext.push(path);
		checkMtx.release();
	}
	#end
	
	public static function main_1() {
		var kind = "?";
		#if cpp
		kind = "C++";
		#elseif cs
		kind = "C#";
		#elseif neko
		kind = "NekoVM";
		#end
		Sys.println("AceSync v" + tools.Macros.buildDate() + ' $kind');
		initMeta();
		
		executableDir = Path.directory(Sys.programPath());
		AseConfig.init();
		
		var args = Sys.args();
		
		var syncNow = false;
		var syncOnce = false;
		var i = 0;
		while (i < args.length) {
			var del = switch (args[i]) {
				case "--base": baseSpriteName = args[i + 1]; 2;
				case "--sync": syncNow = true; 1;
				case "--once": syncNow = true; syncOnce = true; 1;
				case "--folder": prefix = args[i + 1]; 2;
				case "--aseprite": asepritePath = args[i + 1]; 2;
				case "--consent": AseConfig.current.consent = true; AseConfig.save(); 1;
				default: 0;
			}
			if (del > 0) {
				args.splice(i, del);
			} else i++;
		}
		
		projectPath = args[0];
		var lastProjectPath = AseConfig.current.lastProjectPath;
		var saveConfig = false;
		while (projectPath == null) {
			var path = MySysTools.getPath(
				"the path to your project YYP file",
				lastProjectPath != null ? '[leave blank to use "$lastProjectPath" again]' : null
			);
			if (lastProjectPath != null && path == "") path = lastProjectPath;
			if (FileSystem.exists(path)) {
				projectPath = path;
				AseConfig.current.lastProjectPath = path;
				saveConfig = true;
			} else Sys.println('"$path" does not exist!');
		}
		projectDir = Path.directory(projectPath);
		
		watchDir = args[1];
		var lastWatchDir = AseConfig.current.lastWatchPath;
		var autoAsepritesDir = projectDir + "/aseprites";
		if (!FileSystem.exists(autoAsepritesDir)) autoAsepritesDir = null;
		while (watchDir == null) {
			var path = MySysTools.getPath(
				"the path to a folder with your Aseprite files",
				lastWatchDir != null && projectPath == lastProjectPath
				? '[leave blank to use "$lastWatchDir" again]'
				: (autoAsepritesDir != null ? '[leave blank to use "$autoAsepritesDir"]' : null)
			);
			if (path == "") {
				if (lastWatchDir != null && projectPath == lastProjectPath) {
					path = lastWatchDir;
				} else if (autoAsepritesDir != null) {
					path = autoAsepritesDir;
				}
			}
			if (FileSystem.exists(path)) {
				watchDir = path;
				AseConfig.current.lastWatchPath = path;
				saveConfig = true;
			} else Sys.println('"$path" does not exist!');
		}
		watchDir = Path.normalize(watchDir);
		
		if (asepritePath == null) {
			asepritePath = AseConfig.current.asepritePath;
			while (asepritePath == null) {
				var path = MySysTools.getPath("the path to Aseprite executable");
				if (FileSystem.exists(path)) {
					asepritePath = path;
					AseConfig.current.asepritePath = path;
					saveConfig = true;
				} else Sys.println('"$path" does not exist!');
			}
		}
		
		baseSpriteText = null;
		if (!FileSystem.exists("tmp")) FileSystem.createDirectory("tmp");
		
		if (saveConfig) AseConfig.save();
		
		while (AseConfig.current.consent == null) {
			Sys.println('Please enter "y" to confirm that you understand the risks of modifying'
				+ ' your project files and are using adequate backups or version control.');
			Sys.print("> ");
			if (MySysTools.readLine().toLowerCase() == "y") {
				AseConfig.current.consent = true;
				AseConfig.save();
			}
		}
		
		//trace("hi!", watchDir);
		
		baseSpritePath = '$projectDir/sprites/$baseSpriteName/$baseSpriteName.yy';
		if (FileSystem.exists(baseSpritePath)) {
			syncBaseSprite();
		} else {
			Sys.println("No template sprite is defined, looking for first sprite...");
			for (spr in FileSystem.readDirectory('$projectDir/sprites')) {
				var yyPath = '$projectDir/sprites/$spr/$spr.yy';
				if (!FileSystem.exists(yyPath)) continue;
				try {
					var text = File.getContent(yyPath);
					var yySpr:YySprite = YyJsonParser.parse(text);
					if (yySpr.frames.length == 0) continue;
					baseSpritePath = yyPath;
					syncBaseSprite(text, yySpr);
					Sys.println('Picked $spr.');
					break;
				} catch (x) {
					Sys.println('Error checking sprite $spr: ' + x);
					continue;
				}
			}
			if (baseSpriteText == null) {
				Sys.println("Couldn't find a single sprite! Please add one and re-run");
				return;
			}
		}
		
		if (syncNow) {
			Sys.println("Running force-sync...");
			function syncRec(dir:String) {
				for (rel in FileSystem.readDirectory(dir)) {
					var path = dir + "/" + rel;
					if (FileSystem.isDirectory(path)) {
						syncRec(path);
					} else {
						if (isAse(rel)) AseSyncSprite.sync(path);
					}
				}
			}
			syncRec(watchDir);
			flushYyp();
			if (syncOnce) return;
		}
		
		Sys.println("Watching the sprites directory for changes...");
		#if cs
		var fwc = new FileSystemWatcher(watchDir);
		fwc.Filter = "*.aseprite";
		fwc.IncludeSubdirectories = true;
		fwc.EnableRaisingEvents = true;
		
		var filters = NotifyFilters.CreationTime;
		for (filter in [
			NotifyFilters.LastWrite,
			NotifyFilters.FileName,
		]) filters = cs.Syntax.code("{0} | {1}", filters, filter);
		fwc.NotifyFilter = filters;
		
		fwc.add_Created(fwcListener);
		fwc.add_Changed(fwcListener);
		fwc.add_Renamed(fwcListener);
		#else
		var _trace = haxe.Log.trace;
		var fw:PollingFileWatcher, ex:Executor;
		try {
			haxe.Log.trace = function(v, ?i) {}
			ex = Executor.create();
			fw = new PollingFileWatcher(ex, 500);
			fw.subscribe(function(e) {
				//trace(e);
				//Sys.println(e);
				switch (e) {
					case FILE_MODIFIED(file, _, _), FILE_CREATED(file):
						var path = file.path.toString();
						if (!isAse(path)) return;
						path = Path.normalize(path);
						checkMtx.acquire();
						checkNext.push(path);
						checkMtx.release();
					default:
				}
			});
			fw.watch(watchDir);
		} catch (x:Dynamic) {
			Sys.println('Failed to watch the directory! $x');
			return;
		}
		haxe.Log.trace = _trace;
		#end
		Sys.println("You can close the window when you're done.");
		
		var checkPaths:Array<String> = [];
		while (true) {
			Sys.sleep(0.5);
			
			checkMtx.acquire();
			for (path in checkNext) checkPaths.push(path);
			checkNext.resize(0);
			checkMtx.release();
			
			for (path in checkPaths) {
				AseSyncSprite.sync(path);
			}
			checkPaths.resize(0);
			flushYyp();
		}
		#if cs
		fwc.Dispose();
		#else
		fw.stop();
		ex.stop();
		#end
	}
	public static function main() {
		if (false) {
			main_1();
		} else try {
			main_1();
		} catch (x:Dynamic) {
			Sys.println('An error occurred: $x');
			Sys.println(CallStack.toString(CallStack.exceptionStack()));
		}
		Sys.println('Press Enter to exit!');
		MySysTools.readLine();
	}
}