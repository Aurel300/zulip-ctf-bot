package bot.cmd;

import bot.*;
import bot.Command.ExecuteResult;

class Solve extends Command {
  public function new(?streams:Array<String>) super(
       ["solve", "flag", "s"]
      ,"!solve[ <challenge name>]"
      ,"Mark a challenge as solved by you if no arguments are given. If more arguments are given, these names are used as the solvers (don't forget yourself)"
      ,streams
    );
  
  override public function execute(msg:Zulip.ZulipMessage, words:Array<String>):ExecuteResult {
    return (if (words.length >= 1) {
        if (!Main.board.exists(words[0])) return Error("no such challenge");
        Main.board.solve(words[0], words.length > 1 ? words.slice(1) : [msg.sender_full_name]);
        Ok;
      } else Usage);
  }
}
