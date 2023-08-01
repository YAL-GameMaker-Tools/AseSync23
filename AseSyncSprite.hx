package ;
import AseSync.*;
import haxe.io.Path;
import yy.*;
import haxe.macro.Expr.Var;
import sys.FileSystem;
import sys.io.File;
import tools.FileTools;
import tools.MathTools;

/**
 * ...
 * @author YellowAfterlife
 */
class AseSyncSprite {
	static function createGUID():String {
		var result = "";
		for (j in 0 ... 32) {
			if (j == 8 || j == 12 || j == 16 || j == 20) {
				result += "-";
			}
			if (j == 12) {
				result += "4";
			}
			else if (j == 16) {
				result += "89ab".charAt(Std.random(4));
			}
			else {
				result += "0123456789abcdef".charAt(Std.random(16));
			}
		}
		return result;
	}
	static function sync_1(asePath:String, tmp:String, name:String, aseData:AseData, keys:Array<String>, tmpOffset:Int) {
		var yyDir = '$projectDir/sprites/$name';
		var yyPath = '$yyDir/$name.yy';
		var yyRel = 'sprites/$name/$name.yy';
		var spr:YySprite;
		var save = false;
		if (FileSystem.exists(yyPath)) {
			spr = YyJson.parse(File.getContent(yyPath));
		} else {
			save = true;
			spr = YyJson.parse(baseSpriteText);
			spr.frames = [];
			spr.sequence.tracks[0].keyframes.Keyframes = [];
			spr.name = name;
			
			if (projectData == null) projectData = YyJson.parse(File.getContent(projectPath));
			
			var aseNorm = Path.normalize(asePath);
			if (StringTools.startsWith(aseNorm, watchDir + "/")) { // create YYP folder chain
				aseNorm = aseNorm.substring(watchDir.length + 1);
				var dir = Path.directory(aseNorm);
				if (dir != "") {
					if (prefix != "") dir = '$prefix/$dir';
				} else dir = prefix;
				if (dir != "") {
					var pre = "folders";
					var folderPath:String = pre + ".yy";
					var parts = dir.split("/");
					for (part in parts) {
						pre += '/$part';
						folderPath = '$pre.yy';
						var found = false;
						for (folder in projectData.Folders) {
							if (folder.folderPath == folderPath) {
								found = true;
								break;
							}
						}
						if (!found) {
							projectData.Folders.push({
								folderPath: folderPath,
								order: maxOrder,
								resourceVersion: "1.0",
								name: part,
								tags: [],
								resourceType: "GMFolder",
							});
						}
						//trace(part, pre);
					}
					spr.parent.name = parts[parts.length - 1];
					spr.parent.path = folderPath;
				} // dir != ""
				if (!FileSystem.exists(yyDir)) FileSystem.createDirectory(yyDir);
			}
			
			projectData.resources.push({
				id: { name: name, path: 'sprites/$name/$name.yy' },
				order: maxOrder,
			});
		}
		
		var aseSize = aseData.frames[keys[0]].sourceSize;
		var aseWidth = aseSize.w;
		var aseHeight = aseSize.h;
		
		var keyframes = spr.sequence.tracks[0].keyframes.Keyframes;
		var framesPerFrame = spr.sequence.playbackSpeedType == 1;
		
		if (spr.width != aseWidth || spr.height != aseHeight) {
			spr.width = aseWidth;
			spr.height = aseHeight;
			var spr_orig:Int = spr.origin;
			if (spr_orig < 9) {
				var xorig:Int = ((spr_orig % 3) * aseWidth) >> 1;
				var yorig:Int = (Std.int(spr_orig / 3) * aseHeight) >> 1;
				spr.sequence.xorigin = xorig;
				spr.sequence.yorigin = yorig;
			}
			save = true;
		}
		
		var msPerFrame = 0.;
		if (spr.sequence.playbackSpeedType == 0) {
			var frameTimings = [];
			for (i => k in keys) {
				var dur = aseData.frames[k].duration;
				if (frameTimings.indexOf(dur) < 0) frameTimings.push(dur);
			}
			
			var frameTime:Float;
			if (false) { // sprite editor shows overly long frames weirdly, so better not
				var gcd = frameTimings[0];
				for (i in 1 ... frameTimings.length) gcd = MathTools.gcd(gcd, frameTimings[i]);
				frameTime = gcd;
			} else {
				var minTime = frameTimings[0];
				for (i in 1 ... frameTimings.length) {
					var ft = frameTimings[i];
					if (ft < minTime) minTime = ft;
				}
				frameTime = minTime;
			}
			
			var fps = MathTools.roundIfCloseToEps(1000 / frameTime);
			{ // if FPS has too many digits after period, use 10fps for precision instead
				var fpsStr = Std.string(fps);
				var dotAt = fpsStr.indexOf(".");
				if (dotAt >= 0 && dotAt < fpsStr.length - 4) fps = 10;
			}
			msPerFrame = 1000 / fps;
			spr.sequence.playbackSpeed = fps;
			Sys.println('[$name] ref frame time: $frameTime, FPS: $fps');
		}
		
		var time = 0.;
		for (i => key in keys) {
			var af = aseData.frames[key];
			var dur = 1.;
			if (msPerFrame != 0) {
				dur = MathTools.roundIfCloseToEps(af.duration / msPerFrame);
			}
			var sf = spr.frames[i];
			var kf = keyframes[i];
			if (sf == null) {
				sf = YyJson.parse(baseSpriteFrameText);
				var guid = createGUID();
				if (sf.parent != null) {
					sf.parent = { name: name, path: yyRel };
				}
				if (sf.images != null) {
					var img = sf.images[0];
					img.FrameId.name = guid;
					img.FrameId.path = yyRel;
					img.LayerId.name = spr.layers[0].name;
					img.LayerId.path = yyRel;
				}
				sf.name = guid;
				if (sf.compositeImage != null) {
					sf.compositeImage.FrameId.name = guid;
					sf.compositeImage.FrameId.path = yyRel;
				}
				spr.frames.push(sf);
				//
				kf = YyJson.parse(baseSpriteKeyFrameText);
				kf.id = createGUID();
				kf.Key = time;
				kf.Length = dur;
				kf.Channels["0"].Id.name = guid;
				kf.Channels["0"].Id.path = yyRel;
				keyframes.push(kf);
				save = true;
			} else if (kf.Key != time || kf.Length != dur) {
				kf.Key = time;
				kf.Length = dur;
				save = true;
			}
			var tmpInd = tmpOffset + i;
			var src = '$tmp/$tmpInd.png';
			var dstName = sf.compositeImage != null ? sf.compositeImage.FrameId.name : sf.name;
			var dst = yyDir + "/" + dstName + ".png";
			if (!FileTools.compare(src, dst)) {
				Sys.println('Copying $src to $dst...');
				File.copy(src, dst);
			}
			time += dur;
		}
		if (spr.sequence.length != time) {
			spr.sequence.length = time;
			save = true;
		}
		
		// remove extra frames
		var i = spr.frames.length;
		while (--i >= keys.length) {
			var sf = spr.frames[i];
			var guid = sf.compositeImage != null ? sf.compositeImage.FrameId.name : sf.name;
			var path = '$yyDir/$guid.png';
			if (FileSystem.exists(path)) try {
				FileSystem.deleteFile(path);
			} catch (_:Dynamic) {};
			spr.frames.pop();
			keyframes.pop();
			save = true;
		}
		
		if (save) {
			File.saveContent(yyPath, YyJson.stringify(spr));
		}
	}
	public static function sync(asePath:String) {
		var name = (new Path(asePath)).file;
		Sys.println('Syncing $name ($asePath)...');
		
		var tmp = 'tmp/$name';
		if (!FileSystem.exists(tmp)) FileSystem.createDirectory(tmp);
		Sys.command(asepritePath, [
			"-b",
			"--list-tags",
			"--data", '$tmp/data.json',
			asePath,
			"--save-as", '$tmp/0.png',
		]);
		
		var aseData:AseData = {
			var _storeKeys = YyJsonParser.storeKeys;
			YyJsonParser.storeKeys = true;
			var _aseData = YyJsonParser.parse(File.getContent('$tmp/data.json'));
			YyJsonParser.storeKeys = _storeKeys;
			_aseData;
		};
		var keys:Array<String> = cast aseData.frames["__keys__"];
		
		var tags = aseData.meta.frameTags ?? [];
		if (tags.length == 0) {
			sync_1(asePath, tmp, name, aseData, keys, 0);
		} else for (tag in tags) {
			var tname = tag.name == "" ? name : name + "_" + tag.name;
			sync_1(asePath, tmp, tname, aseData, keys.slice(tag.from, tag.to + 1), tag.from);
		}
	}
	
}