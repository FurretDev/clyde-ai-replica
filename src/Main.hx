import haxe.Json;
import haxe.Timer;
import haxe.EntryPoint;
import hxdiscord.DiscordClient;
import sys.io.File;
import sys.FileSystem;
import hxdiscord.utils.Intents;
import hxdiscord.types.*;
import haxe.Http;

using StringTools;

class Main {
	public static var Bot:DiscordClient;
	public static var userAgent:String = "ClydeAIReplica/1.0 (DiscordBot; +NULL)";
	public static var usersOnCooldownAI:Array<String> = [];
	public static var aiMessages:Map<String, Message> = new Map<String, Message>();
	public static var token:String = "";
	public static var openai_token:String = "";
	public static var ai21_token:String = "";
	public static var ai21:Bool = false;

	static function main() {
		if (!FileSystem.exists("config.json")) {
			File.saveContent(haxe.Json.stringify({
				token: "DISCORD TOKEN HERE",
				openai_token: "OPENAI TOKEN HERE"
			}, "\t"), "config.json");
			throw "Config file doesn't exist, the application has generated a new one\nMake sure to edit the new config.json file";
		} else {
			var content:String = File.getContent("config.json");
			var parse:Dynamic = Json.parse(content);
			token = parse.user_token;
			openai_token = parse.openai_token;
			if (parse.ai21 && parse.ai21_token == null) {
				throw "As AI21 is enabled, you would need to use a AI21 token. Head over to the AI21 Playground, and grab your token from the Network tab by pressing F12, it should be \"Authorization: Bearer (something)\"";
			} else if (!parse.ai21 && parse.ai21_token != null) {
				//don't do anything
			} else {
				ai21 = true;
				ai21_token = parse.ai21_token;
				trace("WARNING: AI21 is enabled, Clyde will not use GPT-3.5 turbo anymore and instead it will use AI21's free services. AI21 uses Jurassic-2 instead of GPT-3.5 Turbo, expect Clyde's replies a little stupid from now on");
			}
			if (parse.sad_clyde) {
				Clyde.shutdown = true;
			}
		}
		Bot = new DiscordClient(token, [Intents.ALL], false);
		Bot.onReady = onReady;
		Bot.onMessageCreate = onMessageCreate;
		Bot.connect();
	}

	public static function onReady() {
		trace("Clyde is ready to chat with people!");
	}

	public static function onMessageCreate(m:Message) {
		/*trace(ClydeAIPrompt.generatePrompt(m));
		trace(ai21);*/
		//test purposes
		sys.thread.Thread.create(() -> {
			//trace(ClydeAIPrompt.generatePrompt(m));
			if ((m.content.contains("<@" + Bot.user.id + ">")
				|| m.content.contains("<!@" + Bot.user.id + ">")
				|| m.content.contains("<@!" + Bot.user.id + ">"))
				&& m.author.bot == null) {
				if (!usersOnCooldownAI.contains(m.author.id)) {
					if (ai21) {
						AI21Chat.chat(m);
					} else {
						OpenAIChat.chat(m);
					}
				} else {
					m.reply({content: "Clyde didn't reply yet! Please wait"}, true);
				}
			} else {
				if (m.referenced_message != null && m.author.bot == null) {
					if (m.referenced_message.author.id == Bot.user.id) {
						if (ai21) {
							AI21Chat.chat(m);
						} else {
							OpenAIChat.chat(m);
						}
					}
					/*if (aiMessages.exists(m.referenced_message.id)) {
						if (ai21) {
							AI21Chat.chat(m);
						} else {
							OpenAIChat.chat(m);
						}
					}*/
					if (OpenAIChat.threads.exists(m.channel_id)) {
						if (ai21) {
							AI21Chat.chat(m);
						} else {
							OpenAIChat.chat(m);
						}
					}
				} else {
					if (OpenAIChat.threads.exists(m.channel_id)) {
						if (ai21) {
							AI21Chat.chat(m);
						} else {
							OpenAIChat.chat(m);
						}
					}
				}
			}
		});
	}
}
