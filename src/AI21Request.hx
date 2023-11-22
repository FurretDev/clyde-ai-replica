import sys.ssl.Socket as SocketSSL;
import haxe.io.BytesOutput;
import sys.io.File;
import sys.FileSystem;
import haxe.io.Bytes;
import hxdiscord.endpoints.Endpoints;

class AI21Request {
    var socket:SocketSSL;
    var dataHttp:SomeBytesZ;
    public var timer:haxe.Timer;
    var respond:Bool = false;
    public function new() {

    }
    public function main(prompt:String):String {
        //trace("is this being called or not");
        dataHttp = new SomeBytesZ();
        socket = new SocketSSL();
        socket.connect(new sys.net.Host("api.openai.com"), 443);
        var stringBuf = new StringBuf();
        stringBuf.add("POST /v1/chat/completions HTTP/1.1\r\n");
        stringBuf.add("Host: api.openai.com\r\n");
        stringBuf.add("Content-Type: application/json\r\n");
        stringBuf.add("Authorization: Bearer "+Main.ai21_token+"\r\n");
        stringBuf.add("Content-Length: " + haxe.Json.stringify({
            model: "gpt-4",
            prompt: prompt,
            temperature: 2,
            max_tokens: 1500
        }).length + "\r\n");
        stringBuf.add("Connection: close\r\n\r\n");
        stringBuf.add(haxe.Json.stringify({
            model: "gpt-4",
            prompt: prompt,
            temperature: 2,
            max_tokens: 1500
        }));
        //trace(stringBuf.toString());
        var bytes:Bytes = Bytes.ofString(stringBuf.toString());
        //trace(bytes.toString());
        socket.output.writeFullBytes(bytes, 0, bytes.length);
        var output:String = "";
        while (!respond) {
            var input = socket.input;
            var evenMoreBytes = new SomeBytesZ();
            try {
                var data = Bytes.alloc(1024);
                var readed = input.readBytes(data, 0, data.length);
                if (readed <= 0) break;
                evenMoreBytes.writeBytes(data.sub(0,readed));
                var bytes:Bytes = evenMoreBytes.readAllAvailableBytes();
                //trace(bytes);
                dataHttp.writeBytes(bytes);
                if (bytes.length == 0) {
                    respond = true;
                }
            } catch (err) {
                //trace(err);
                respond = true;
            }
        }
        return dataHttp.readAllAvailableBytes().toString().split("\r\n\r\n")[1];
    }

    public function destroy() {
        socket.close();
        socket = null;
        respond = true;
    }

    public function chat(messages:Dynamic, system:String):String {
        //trace("is this being called or not");
        var models:Array<String> = ["gpt-3.5-turbo", "gpt-3.5-turbo-0301", "gpt-3.5-turbo-0613", "gpt-3.5-turbo-16k", "gpt-3.5-turbo-16k-0613"];
        //var model:String = models[Std.random(models.length)];
        var model:String = "gpt-3.5-turbo";
        var json:Dynamic = {
            system: system,
            messages: messages,
            hideSelectors: true,
            outputId: "1",
            modelId: "j2-ultra",
            content: "",
            maxTokens: 1024,
            temperature: 0.7,
            topP: 1,
            stopSequences: [
                
            ],
            presencePenalty: {
                scale: 0
            },
            frequencyPenalty: {
                scale: 0
            },
            countPenality: {
                scale: 0
            }
        }
        //trace(model);
        dataHttp = new SomeBytesZ();
        socket = new SocketSSL();
        socket.connect(new sys.net.Host("api.ai21.com"), 443);
        var stringBuf = new StringBuf();
        stringBuf.add("POST /studio/v1/j2-ultra/chat HTTP/1.1\r\n");
        stringBuf.add("Host: api.ai21.com\r\n");
        stringBuf.add("Content-Type: application/json\r\n");
        //trace(token);
        stringBuf.add("Authorization: Bearer "+Main.ai21_token+"\r\n");
        stringBuf.add("User-Agent: " + Main.userAgent + "\r\n");
        stringBuf.add("Content-Length: " + haxe.Json.stringify(json).length + "\r\n");
        stringBuf.add("Connection: close\r\n\r\n");
        stringBuf.add(haxe.Json.stringify(json));
        //trace(haxe.Json.stringify(json));
        //trace(stringBuf.toString());
        var bytes:Bytes = Bytes.ofString(stringBuf.toString());
        //trace(bytes.toString());
        socket.output.writeFullBytes(bytes, 0, bytes.length);
        var output:String = "";
        while (!respond) {
            var input = socket.input;
            var evenMoreBytes = new SomeBytesZ();
            try {
                var data = Bytes.alloc(1024);
                var readed = input.readBytes(data, 0, data.length);
                if (readed <= 0) break;
                evenMoreBytes.writeBytes(data.sub(0,readed));
                var bytes:Bytes = evenMoreBytes.readAllAvailableBytes();
                //trace(bytes);
                dataHttp.writeBytes(bytes);
                if (bytes.length == 0) {
                    respond = true;
                }
            } catch (err) {
                //trace(err);
                respond = true;
            }
        }
        var response = dataHttp.readAllAvailableBytes().toString();
        //trace(response);
        /*if (response.length < 5) {
            for (i in 0...OpenAIChat.OpenAITimers.timers.length) {
                OpenAIChat.OpenAITimers.timers[i].stop();
            }
            response = "Failed.\n\n{\"failed\": \"failed\"}";
        } else {
            var json:Dynamic = haxe.Json.parse(response.substring(response.indexOf("{"), response.lastIndexOf("}")+1));
            if (json.error != null) {
                if (json.error.type != "invalid_request_error") {
                    trace('[OpenAI gave error]: Token: ${token}\n\n${haxe.Json.stringify(json, "\t")}\n\nIssue notified!');
                    Endpoints.sendMessage("1133476267048566874", {
                        "embeds": [
                            {
                                "title": "⚠️ OpenAI failed to reply",
                                "description": "The API returned a JSON with an error field.",
                                "color": 16711680,
                                "fields": [
                                    {
                                        "name": "JSON",
                                        "value": '```json\n${haxe.Json.stringify(json, "\t")}\n```',
                                        "inline": false
                                    },
                                    {
                                        "name": "Token",
                                        "value": token,
                                        "inline": false
                                    }
                                ]
                            }
                        ]
                    }, null, false);
                }
            } else {
                trace('[OpenAI replied]: ${json.choices[0].message.content}');
            }
        }*/
        return response;
    }
}

class SomeBytesZ {
    public var available(default, null):Int = 0;
    private var currentOffset:Int = 0;
    private var currentData: Bytes = null;
    private var chunks:Array<Bytes> = [];

    public function new() {

    }

    public function writeBytes(data:Bytes) {
        chunks.push(data);
        available += data.length;
    }

    public function readAllAvailableBytes():Bytes {
        return readBytes(available);
    }

    public function readBytes(count:Int):Bytes {
        var count2 = Std.int(Math.min(count, available));
        var out = Bytes.alloc(count2);
        for (n in 0 ... count2) out.set(n, readByte());
        return out;
    }

    public function readByte():Int {
        if (available <= 0) throw 'Not bytes available';
        while (currentData == null || currentOffset >= currentData.length) {
            currentOffset = 0;
            currentData = chunks.shift();
        }
        available--;
        return currentData.get(currentOffset++);
    }
}