package bot;

class Board {
  public final rootMessage:Int;
  public final challMap:Map<String, Challenge> = [];
  public final workMap:Map<String, String> = [];
  public final challenges:Array<Challenge> = [];
  
  public function new(rootMessage:Int) {
    this.rootMessage = rootMessage;
  }
  
  public function solve(name:String, by:Array<String>):Void {
    // send message?
    challMap[name].solved = true;
    challMap[name].solvedBy = by;
    [ for (worker => chall in workMap) if (chall == name) worker ].map(workMap.remove);
    update();
  }
  
  public function exists(name:String):Bool return challMap.exists(name);
  
  public function add(challenge:Challenge):Void {
    challenges.push(challMap[challenge.name] = challenge);
    update();
  }
  
  public function remove(name:String):Void {
    challenges.remove(challMap[name]);
    challMap.remove(name);
    update();
  }
  
  public function update():Void {
    var msg = new StringBuf();
    msg.add(":triangular_flag: :triangular_flag: :triangular_flag: **flagz4lyfe** :triangular_flag: :triangular_flag: :triangular_flag:");
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
    for (command in Main.commands) {
      msg.add('\n* `${command.usage}` (${command.aliases.slice(1).map(a -> "`!$a`").join(" ")}) - ${command.description}');
    }
    msg.add("\n\nPlease do not send any messages into the `bot` topic, it is reserved for this bot "
      + "(that way the overview board can be seen by clicking the topic in the sidebar). "
      + "Send your commands to the `cmd` topic.");
    Main.client.messages.update({message_id: rootMessage, content: msg.toString()});
  }
}
