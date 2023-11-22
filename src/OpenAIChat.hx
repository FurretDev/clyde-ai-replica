import hxdiscord.types.User;
import hxdiscord.types.structTypes.Channel;
import hxdiscord.endpoints.Endpoints;
import sys.io.File;
import haxe.Json;
import hxdiscord.types.Message;
import haxe.Http;

using StringTools;

class OpenAIChat {
	public static var chatHistory:Map<String, Array<Dynamic>> = new Map<String, Array<Dynamic>>();
	public static var threads:Map<String, Array<Dynamic>> = new Map<String, Array<Dynamic>>();
	public static var aiMessages:Map<String, Array<Dynamic>> = new Map<String, Array<Dynamic>>();
	public static var convos:Map<String, Dynamic> = new Map<String, Dynamic>();
	static var actions:Array<String> = ["CREATE_THREAD", "REACT_MESSAGE", "NO_REPLY"];
	public static var errorMessages:Array<String> = [
		"oops, I seem to have hit a rock on the road, my developers are already on their way to fix me up.",
		"Oops, looks like I tripped over a bug. Don't worry, my developers are already on the case to squash it.",
		"Whoopsie! It seems I took a wrong turn in the code. Rest assured, my trusty developers are working to set me back on track.",
		"Uh-oh! It appears I stumbled upon an error. Fear not, my skilled developers are rushing to iron out the kinks.",
		"Well, well, well... It seems I've encountered a glitch. But no worries, my diligent developers are already working their magic to restore smooth operation.",
		"Oopsie-daisy! It seems I got caught in a coding hiccup. But fret not, my talented developers are on standby to untangle the mess."
	];

	public static function chat(m:Message) {
		trace("g");
		sys.thread.Thread.create(() -> {
			var content:String = m.content.replace("<@" + Main.Bot.user.id + ">", "");
			content = CoolUtil.sanitizeContent(content);
			if (!convos.exists(m.channel_id)) {
				var convo:Dynamic = {
					users: [m.author.username]
				}
				convos.set(m.channel_id, convo);
			}
			var ids:Array<String> = CoolUtil.extractIDsFromText(content);
			for (id in ids) {
				var user:User = Endpoints.getUser(id);
				// make it check for discrims
				var username:String = "";
				if (user.discriminator != "0") {
					username = user.username + "#" + user.discriminator;
				} else {
					username = user.username;
				}
				content = content.replace('<@${id}>', '@${username}');
			}
			// trace(content);
			Sys.println('[Clyde AI]: User ${m.author.username} asked something: ${content}');
			Endpoints.triggerTypingIndicator(m.channel_id);
			if (chatHistory.get('${m.channel_id}-${m.author.id}') == null) {
				// trace("f");
				var obj:Array<Dynamic> = [
					{content: ClydeAIPrompt.generatePrompt(m), role: "system"},
					{content: '${content}', role: "user"}
				];
				// trace(obj);
				chatHistory.set('${m.channel_id}-${m.author.id}', obj);
			} else {
				// trace("not f");
				var obj:Array<Dynamic> = chatHistory.get('${m.channel_id}-${m.author.id}');
				obj.push({content: '${content}', role: "user"});
				chatHistory.set('${m.channel_id}-${m.author.id}', obj);
			}
			var OpenAIChatRequest:OpenAIRequest = new OpenAIRequest();
			// trace(chatHistory.get('${m.channel_id}-${m.author.id}'));
			var response:String = OpenAIChatRequest.chat(chatHistory.get('${m.channel_id}-${m.author.id}'));
			// trace(response);
			var json:Dynamic = haxe.Json.parse(response.substring(response.indexOf("{"), response.lastIndexOf("}") + 1));
			if (json.choices != null) {
				if (json.choices[0].message != null) {
					var curObj:Dynamic = chatHistory.get('${m.channel_id}-${m.author.id}');
					curObj.push(json.choices[0].message);
					chatHistory.set('${m.channel_id}-${m.author.id}', curObj);
				}
			}
			if (json.choices != null) {
				var response:String = json.choices[0].message.content;
				response = response.replace("https://", "");
				response = response.replace("http://", "");
				var madethread:Bool = false;
				var threadId:String = "";
				var failed:Bool = false;
				var thread:Dynamic = null;
				var message:Message = null;
				var regex = ~/({.*?})/g;
				var matches:Array<String> = [];
				var daResponse:String = response;
				while (regex.match(daResponse)) {
					matches.push(regex.matched(0));
					// trace(response);
					daResponse = regex.matchedRight();
					// trace(response);
				}

				var jsons:Array<Dynamic> = [];
				for (match in matches) {
					// m.reply({content:'`${match}`'});
					try {
						// m.reply({content:"`"+match.trim()+"`"},true);
						var parsedJson:Dynamic = Json.parse(match.trim());
						trace(parsedJson.action);
						for (i in 0...actions.length) {
							if (parsedJson.action == actions[i]) {
								jsons.push(parsedJson);
								// response = response.replace(match, "");
							}
						}
					} catch (err) {
						trace(err);
						/*trace(err);
							trace('```\n${err.toString()}\n${haxe.CallStack.toString(haxe.CallStack.exceptionStack())}```'); */
					}
				}
				Sys.println("[Clyde AI] AI replied with: " + response);
				message = new Message(Endpoints.sendMessage(m.channel_id, {content: response, allowed_mentions: {parse: []}}, m.id, true), Main.Bot);
				if (message.id != null) {
					Main.aiMessages.set(message.id, message);
				}
				// trace(message.id);

				Main.usersOnCooldownAI.remove(m.author.id);
			} else {
				if (json.error != null) {
					m.reply({content:"Uh oh, I've encountered an issue. Rest assured, I have my best people working on the problem."}, true);
				}
			}
		});
	}
}

class AIPrompts {
	public static function generateInitialPrompt(extraShit:String, m:Message):String {
		var s:String = "";
		var stringBuf:StringBuf = new StringBuf();
		var data:Dynamic = null;
		var getData:Http = new Http("https://discord.com/api/v9/users/" + m.author.id + "/profile?with_mutual_guilds=false&with_mutual_friends_count=false");
		getData.addHeader("User-Agent", "ClydeAIReplica/1.0 (DiscordBot; +NULL)");
		getData.addHeader("Authorization", Main.token);
		getData.onData = (d:String) -> {
			data = Json.parse(d);
			// trace(d);
		}
		getData.onError = (d:String) -> {
			// trace(d);
		}
		getData.request(false);
		stringBuf.add("You are named Clyde - and are currently chatting in a Discord server.\n\n");
		stringBuf.add("You are friendly, warm, and farcical. You must always be extremely concise. If the user is chatting casually, your responses must be less than 1 sentence, sometimes just a word or two. If the user needs help, disregard the length restriction, answer technical or knowledge-based questions with useful details and reasoning. If insulted, respond with a similar insult. Communicate responses in lowercase without punctuation, similar to the style used in chat rooms. Use unicode emoji rarely. Do not refer to yourself as a bot, AI Assistant, or any equivalent term.\n\n");
		stringBuf.add("You need to always reply in lowercase, without punctuation and giving short answers\n\n");
		stringBuf.add("Do not include name: or message: in your response.\n\n");
		stringBuf.add("Information about your environment:\n\n");
		stringBuf.add("You can use this information about the chat participants in the conversation in your replies. Use this information to answer questions.\n\n");
		stringBuf.add(m.author.username_f + "\n");
		stringBuf.add("- pronouns: " + data.user_profile.pronouns + "\n");
		stringBuf.add("- bio: " + data.user_profile + "\n\n");
		stringBuf.add("You only have access to a limited number of text chats in this channel. You cannot access any other information on Discord. You can't see images or avatars. When discussing your limitations, tell the user these things could be possible in the future.\n\n");
		stringBuf.add("Current time: " + Date.now() + "\n");
		return stringBuf.toString();
	}
}
