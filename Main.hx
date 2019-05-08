using StringTools;

typedef Challenge = {
     name:String
    ,category:String
    ,worth:Null<Int>
    ,solved:Bool
    ,solvedBy:Array<String>
  };

class Main {
  static var client:Zulip;
  static var rootMessage:Int = 136;
  
  static var challMap:Map<String, Challenge> = [];
  static var workMap:Map<String, String> = [];
  static var challenges:Array<Challenge> = [];
  
  static function main():Void Zulip.create({zuliprc: "zuliprc"}).then(init);
  
  static function updateBoard():Void {
    var msg = new StringBuf();
    msg.add("**flagz4lyfe**");
    if (challenges.length > 0) {
      var cats:Map<String, Array<Challenge>> = [];
      var catNames = [];
      for (chall in challenges) {
        if (!cats.exists(chall.category)) {
          cats[chall.category] = [];
          catNames.push(chall.category);
        }
        cats[chall.category].push(chall);
      }
      catNames.sort(Reflect.compare);
      for (category in catNames) {
        var challs = cats[category];
        challs.sort((a, b) -> Reflect.compare(a.name, b.name));
        var solved = challs.filter(c -> c.solved).length;
        msg.add('\n\n**${category}:** (${solved} / ${challs.length})');
        msg.add("\n\n| Challenge | Worth | Active members |");
        msg.add("\n| --- | --- | --- |");
        for (chall in challs) {
          msg.add("\n| ");
          msg.add(chall.solved ? ":check_mark:" : ":cross_mark:");
          msg.add(' ${chall.solved ? "~~" : ""}**${chall.name}**${chall.solved ? "~~" : ""} ');
          msg.add('| ' + (chall.worth != null ? '${chall.worth}' : "n/a"));
          if (chall.solved) {
            msg.add('| *Solved by: ${chall.solvedBy.join(", ")}* :tada: |');
          } else {
            var active = [ for (worker => wc in workMap) if (wc == chall.name) worker ];
            msg.add('| ${active.join(", ")} |');
          }
        }
      }
    } else {
      msg.add('\n\n(no challenges - add some with !addchallenge)');
    }
    msg.add("\n\n**Commands:**\n");
    msg.add("\n* `!addchallenge <name> <category>[ <points>]` (`!ac`) - adds a challenge to the overview board, "
      + "the name will be used to create a new stream, so it should only contain alphanumerics");
    msg.add("\n* `!removechallenge <name>` (`!rc`) - removes a challenge from the board by name");
    msg.add("\n* `!solve <name>[ <solver>...]` (`!s`) - mark a challenge as solved by you if no arguments are given, "
      + "if more arguments are present, these names are used as the solvers (don't forget yourself)");
    msg.add("\n* `!workon[ <name>]` (`!w`) - mark yourself as working on the given challenge, "
      + "no arguments indicate you are not working on anything");
    msg.add("\n\nPlease do not send any messages into the `bot` topic, it is reserved for this bot "
      + "(that way the overview board can be seen by clicking the topic in the sidebar). "
      + "Send your commands to the `cmd` topic.");
    client.messages.update({message_id: rootMessage, content: msg.toString()});
  }
  
  static function solve(name:String, by:Array<String>):Void {
    // send message?
    challMap[name].solved = true;
    challMap[name].solvedBy = by;
    [ for (worker => chall in workMap) if (chall == name) worker ].map(workMap.remove);
    updateBoard();
  }
  
  static function handleMessage(m:Zulip.ZulipMessage):Void {
    var trimmed = m.content.trim();
    if (trimmed.charAt(0) != "!") return;
    var spl = trimmed.split(" ");
    var cmd = spl.shift().substr(1);
    var subusage = (null:String);
    function usage(?err:String):Void {
      
    }
    switch (cmd) {
      case "a" | "ac" | "add" | "addchall" | "addchallenge": subusage = "!addchallenge <name> <category>[ <points>]";
      function add(name:String, category:String, ?worth:Int):Void {
        if (challMap.exists(name)) return usage("challenge alredy exists");
        challenges.push(challMap[name] = {
           name: name
          ,category: category
          ,worth: worth
          ,solved: false
          ,solvedBy: null
        });
        updateBoard();
      }
      switch (spl) {
        case [name, category, Std.parseInt(_) => worth]: add(name, category, worth);
        case [name, category]: add(name, category);
        case _: usage();
      }
      case "r" | "rc" | "remove" | "removechall" | "removechallenge": subusage = "!removechallenge <name>";
      switch (spl) {
        case [name]:
        if (!challMap.exists(name)) return usage("no such challenge");
        challenges.remove(challMap[name]);
        challMap.remove(name);
        updateBoard();
        case _: usage();
      }
      case "w" | "work" | "workon": subusage = "!workon[ <challenge name>]";
      switch (spl) {
        case [name]:
        if (!challMap.exists(name)) return usage("no such challenge");
        workMap[m.sender_full_name] = name;
        updateBoard();
        case []:
        workMap.remove(m.sender_full_name);
        updateBoard();
        case _: usage();
      }
      case "s" | "flag" | "solve": subusage = "!solve <challenge name>[ <solver>...]";
      if (spl.length >= 1) {
        if (!challMap.exists(spl[0])) return usage("no such challenge");
        solve(spl[0], spl.length > 1 ? spl.slice(1) : [m.sender_full_name]);
      } else usage();
      case _:
    }
  }
  
  static function init(client:Zulip):Void {
    Main.client = client;
    js.Node.process.on("unhandledRejection", err -> throw err);
    
    updateBoard();
    
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
