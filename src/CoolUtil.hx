class CoolUtil {
	public static function extractIDsFromText(text:String):Array<String> {
		var ids:Array<String> = [];

		var startIndex = text.indexOf("<@");
		while (startIndex != -1) {
			var endIndex = text.indexOf(">", startIndex);
			if (endIndex != -1) {
				var id = text.substring(startIndex + 2, endIndex);
				ids.push(id);
				startIndex = text.indexOf("<@", endIndex);
			} else {
				break;
			}
		}

		return ids;
	}
	public static function generateShit():String {
		var randomBytes:String = "";
        var abcd:Array<String> = "abcdefghijklmnopqrstuvwxyz".split("");
        for (i in 0...2) {
			randomBytes += abcd[Std.random(abcd.length)];
		}
		for (i in 0...2) {
			randomBytes += Std.string(Std.random(5)).substring(0, 2);
		}
		return randomBytes;
	}
}