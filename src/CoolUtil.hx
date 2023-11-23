using StringTools;
import hxdiscord.types.User;
import hxdiscord.types.structTypes.Channel;
import hxdiscord.endpoints.Endpoints;
import hxdiscord.types.Message;
import haxe.Json;

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

	public static function sanitizeContent(input:String):String {
		//FINISHING TOMORROW
		/**
			Some text is removed from the initial prompt before the bot sees it. Namely (in order of `.replace` calls):
			- Role mentions (always removed, replaced with nothing)
			- User mentions (for users Clyde knows about, replaced with the text `@username`, otherwise replaced with nothing)
			- ChatML tags (namely `<|im_start|>` and `<|im_end|>`)

			The output is transformed back:
			- replacing `@username` with a true user mention
			- evaluating `@gif("search term")` by making requests to the Tenor API and replacing it with a link

			The model is likely GPT 3.5 Turbo (effectively ChatGPT with a different training prompt).
		**/

		// I have no idea what are ChatML tags so fuck them
		var regex:EReg = ~/<@&[^>]+>/g;
		var output:String = regex.replace(input, "");
		var ids:Array<String> = CoolUtil.extractIDsFromText(output);
		for (id in ids) {
			var user:User = Endpoints.getUser(id);
			//make it check for discrims
			var username:String = "";
			if (user.discriminator != "0") {
				username = user.username + "#" + user.discriminator;
			} else {
				username = user.username;
			}
			output = output.replace('<@${id}>','@${username}');
		}
		return output;
	}
}
