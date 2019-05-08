package bot.cmd;

import bot.*;
import bot.Command.ExecuteResult;

class AddChallenge extends Command {
  public function new(?streams:Array<String>) super(
       ["addchallenge", "add", "ac", "a"]
      ,"!addchallenge <name> <category>[ <points>]"
      ,"Adds a challenge to the overview board. The name will be used to create a new stream, so it should only contain alphanumerics."
      ,streams
    );
  
  override public function execute(msg:Zulip.ZulipMessage, words:Array<String>):ExecuteResult {
    function add(name:String, category:String, ?worth:Int):ExecuteResult {
      if (Main.board.exists(name)) return Error("challenge alredy exists");
      Main.board.add({
           name: name
          ,category: category
          ,worth: worth
          ,solved: false
          ,solvedBy: null
        });
      return Ok;
    }
    return (switch (words) {
        case [name, category, Std.parseInt(_) => worth]: add(name, category, worth);
        case [name, category]: add(name, category);
        case _: Usage;
      });
  }
}
