import hxdiscord.types.structTypes.Channel;
import hxdiscord.endpoints.Endpoints;
import hxdiscord.types.Message;
import sys.io.File;
import haxe.Json;

using StringTools;

class AI21Chat {
	public static var chatHistory:Map<String, Array<Dynamic>> = new Map<String, Array<Dynamic>>();
	public static var threads:Map<String, Array<Dynamic>> = new Map<String, Array<Dynamic>>();
	public static var aiMessages:Map<String, Array<Dynamic>> = new Map<String, Array<Dynamic>>();
	static var actions:Array<String> = ["CREATE_THREAD", "REACT_MESSAGE", "WEB_SEARCH", "WEB_SCRAPE"];
	public static var errorMessages:Array<String> = [
		"oops, I seem to have hit a rock on the road, my developers are already on their way to fix me up.",
		"Oops, looks like I tripped over a bug. Don't worry, my developers are already on the case to squash it.",
		"Whoopsie! It seems I took a wrong turn in the code. Rest assured, my trusty developers are working to set me back on track.",
		"Uh-oh! It appears I stumbled upon an error. Fear not, my skilled developers are rushing to iron out the kinks.",
		"Well, well, well... It seems I've encountered a glitch. But no worries, my diligent developers are already working their magic to restore smooth operation.",
		"Oopsie-daisy! It seems I got caught in a coding hiccup. But fret not, my talented developers are on standby to untangle the mess."
	];

	public static function chat(m:Message) {
		Endpoints.triggerTypingIndicator(m.channel_id);
		Sys.println('[Clyde]: User ${m.author.username_f} asked something: ${m.content}');
		var history:Dynamic = chatHistory.get('${m.author.id}-${m.channel_id}');
		var chat:Array<Dynamic> = [
			{
				text: m.content,
				id: CoolUtil.generateShit(),
				role: "user"
			}
		];
		if (history == null) {
			// Create the chat
			chatHistory.set('${m.author.id}-${m.channel_id}', chat);
		} else {
			// Append the chat variable to the already chat history
			var chat:Dynamic = {
				text: m.content,
				id: CoolUtil.generateShit(),
				role: "user"
			};
			var curChat:Array<Dynamic> = chatHistory.get('${m.author.id}-${m.channel_id}');
			// Check if the chat has been going for too long, if that's the case, revert it
			if (curChat.length == 16) {
				var chat:Array<Dynamic> = [
					{
						text: m.content,
						id: CoolUtil.generateShit(),
						role: "user"
					}
				];
				chatHistory.set('${m.author.id}-${m.channel_id}', chat);
			} else {
				var chat:Dynamic = {
					text: m.content,
					id: CoolUtil.generateShit(),
					role: "user"
				};
				curChat.push(chat);
				chatHistory.set('${m.author.id}-${m.channel_id}', curChat);
			}
		}
		var request:AI21Request = new AI21Request();
		var response = request.chat(chatHistory.get('${m.author.id}-${m.channel_id}'), ClydeAIPrompt.generatePrompt(m));
		var splitIndex = response.indexOf("\r\n\r\n");

		var jsonResponse = response.substring(splitIndex + 4);
		if (!response.startsWith("HTTP/1.1 200 OK")) {
			//trace(haxe.Json.stringify(chatHistory.get('${m.author.id}-${m.channel_id}'), "\t"));
			m.reply({content: "Oopsie! Looks like the AI chatbot ate too many cookies and got a sugar overdose! It's currently experiencing a funny error message, resulting in some wacky responses.\nError: `"
				+ response.split("\r\n")[0]
				+ "`\nReply from the server: `"
				+ jsonResponse
				+
				"`\n\nAs a security measure, this chat has been cleared and Cookiaria will not remember the previous conversation, if this error persists contact Furret"}, true);
			chatHistory.set('${m.author.id}-${m.channel_id}', null);
		} else {
			var parsed:Dynamic = haxe.Json.parse(jsonResponse);
			//trace(parsed);
			var message:Message = null;

			if (parsed.outputs[0].text == "" || parsed.outputs[0].text == null) {
				chatHistory.set('${m.author.id}-${m.channel_id}', null);
				AI21Chat.chat(m);
			} else {
				Sys.println('[Clyde]: Clyde replied with ${parsed.outputs[0].text}');
				message = new Message(Endpoints.sendMessage(m.channel_id, {content: parsed.outputs[0].text, allowed_mentions: {parse: []}}, m.id, true),
					Main.Bot);
				if (message.id != null) {
					Main.aiMessages.set(message.id, message);
				}

				var curChat:Array<Dynamic> = chatHistory.get('${m.author.id}-${m.channel_id}');
				curChat.push({
					text: parsed.outputs[0].text,
					role: "assistant",
					completionId: parsed.id,
					finishReason: {
						reason: "endoftext",
						length: null,
						sequence: null,
					},
					id: CoolUtil.generateShit()
				});
				chatHistory.set('${m.author.id}-${m.channel_id}', curChat);
				//trace(haxe.Json.stringify(curChat));
				//trace(curChat);
			}
		}
	}
}
