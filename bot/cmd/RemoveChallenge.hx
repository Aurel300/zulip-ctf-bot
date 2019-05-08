package bot.cmd;

import bot.*;
import bot.Command.ExecuteResult;

class RemoveChallenge extends Command {
  public function new(?streams:Array<String>) super(
       ["removechallenge", "remove", "rc", "r"]
      ,"!removechallenge <name>"
      ,"Removes a challenge from the board by name."
      ,streams
    );
  
  override public function execute(msg:Zulip.ZulipMessage, words:Array<String>):ExecuteResult {
    return (switch (words) {
        case [name]:
        if (!Main.board.exists(name)) return Error("no such challenge");
        Main.board.remove(name);
        Ok;
        case _: Usage;
      });
  }
}
