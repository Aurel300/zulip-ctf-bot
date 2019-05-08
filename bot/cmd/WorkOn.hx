package bot.cmd;

import bot.*;
import bot.Command.ExecuteResult;

class WorkOn extends Command {
  public function new(?streams:Array<String>) super(
       ["workon", "work", "w"]
      ,"!workon[ <challenge name>]"
      ,"Mark yourself as working on the given challenge. No arguments indicate you are not working on anything."
      ,streams
    );
  
  override public function execute(msg:Zulip.ZulipMessage, words:Array<String>):ExecuteResult {
    return (switch (words) {
        case [name]:
        if (!Main.board.challMap.exists(name)) return Error("no such challenge");
        Main.board.workMap[msg.sender_full_name] = name;
        Main.board.update();
        Ok;
        case []:
        Main.board.workMap.remove(msg.sender_full_name);
        Main.board.update();
        Ok;
        case _: Usage;
      });
  }
}
