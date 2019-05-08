import bot.*;

using StringTools;

class Main {
  static inline final ROOT_MESSAGE_ID = 136;
  static inline final COMMAND_CHAR = "!";
  static final STREAMS = ["bot-test"];
  
  public static var client:Zulip;
  public static var board = new Board(ROOT_MESSAGE_ID);
  public static var commands = [
       new bot.cmd.AddChallenge(["bot-test"])
      ,new bot.cmd.RemoveChallenge(["bot-test"])
      ,new bot.cmd.Solve(["bot-test"])
      ,new bot.cmd.WorkOn(["bot-test"])
    ];
  
  static function main():Void {
    js.Node.process.on("unhandledRejection", err -> throw err);
    Zulip.create({zuliprc: "zuliprc"}).then(init);
  }
  
  static function handleMessage(m:Zulip.ZulipMessage):Void {
    var trimmed = m.content.trim();
    if (trimmed.charAt(0) != COMMAND_CHAR) return;
    var words = trimmed.split(" ");
    var cmd = words.shift().substr(COMMAND_CHAR.length);
    
    for (command in commands) {
      if (command.streams != null && command.streams.indexOf(m.display_recipient) == -1) continue;
      if (command.aliases.indexOf(cmd) == -1) continue;
      switch (command.execute(m, words)) {
        case Ok:
        case Usage: client.messages.send({to: m.display_recipient, type: "stream", subject: m.subject, content: 'Usage: ${command.usage}'});
        case Error(err): client.messages.send({to: m.display_recipient, type: "stream", subject: m.subject, content: 'Error: ${err}'});
      }
    }
  }
  
  static function init(client:Zulip):Void {
    Main.client = client;
    
    board.update();
    
    var queueId = (null:String);
    var lastEventId = -1;
    client.queues.register({
         event_types: ["message"]
        ,narrow: [["stream", "bot-test"]]
      }).then(res -> {
        if (res.result != "success") throw res.msg;
        queueId = res.queue_id;
        lastEventId = res.last_event_id;
      });
    
    js.Node.process.on("SIGINT", () -> {
        client.queues.deregister({queue_id: queueId}).then(res -> js.Node.process.exit(0));
      });
      
    js.Node.setInterval(function ():Void {
        if (queueId == null) return;
        client.events.retrieve({
             queue_id: queueId
            ,last_event_id: lastEventId
            ,dont_block: true
          }).then(res -> {
              if (res.result != "success") throw res.msg;
              for (event in res.events) {
                if (event.id > lastEventId) lastEventId = event.id;
                if (event.type == "message") handleMessage(event.message);
              }
            });
      }, 1500 * 1);
  }
}
