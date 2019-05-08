package bot;

class Command {
  public final name:String;
  public final aliases:Array<String>;
  public final usage:String;
  public final description:String;
  public final streams:Array<String>;
  
  function new(aliases:Array<String>, usage:String, description:String, ?streams:Array<String>) {
    this.name = aliases[0];
    this.aliases = aliases;
    this.usage = usage;
    this.description = description;
    this.streams = (streams != null ? streams : []);
  }
  
  public function execute(msg:Zulip.ZulipMessage, words:Array<String>):ExecuteResult {
    return Ok;
  }
}

enum ExecuteResult {
  Ok;
  Usage;
  Error(err:String);
}
