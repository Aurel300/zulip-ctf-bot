import js.lib.Promise;

@:jsRequire("zulip-js")
extern class Zulip {
  @:selfCall static function create(?config:{zuliprc:String}):Promise<Zulip>;
  
  var config:{};
  var accounts:ZulipAccounts;
  var events:ZulipEvents;
  // ...
  var messages:ZulipMessages;
  var queues:ZulipQueues;
}

typedef ZulipResult = {result:String, msg:String};

extern class ZulipAccounts {
  function retrieve():Promise<ZulipResult>;
}

extern class ZulipEvents {
  function retrieve(_:{
       ?queue_id:String
      ,?last_event_id:Int
      ,?dont_block:Bool
    }):Promise<ZulipResult & {events:Array<ZulipEvent>}>;
}

extern class ZulipMessages {
  function retrieve(?_:{
      ?narrow:Dynamic
    }):Promise<Dynamic>;
  function send(_:{
       to:String
      ,type:String
      ,subject:String
      ,content:String
    }):Promise<ZulipResult & {id:Int}>;
  function update(_:{
       message_id:Int
      ,content:String
    }):Promise<ZulipResult>;
}

typedef ZulipMessage = {
     avatar_url:String
    ,client:String
    ,content:String
    ,content_type:String
    ,display_recipient:String
    ,?flags:Array<String>
    ,id:Int
    ,?is_me_message:Bool
    ,?reactions:Array<Dynamic>
    ,recipient_id:Int
    ,sender_email:String
    ,sender_full_name:String
    ,sender_id:Int
    ,sender_realm_str:String
    ,sender_short_name:String
    ,?stream_id:String
    ,subject:String
    ,subject_links:Array<Dynamic>
    ,timestamp:Int
    ,type:String // stream, private
  };

typedef ZulipEvent = {
     id:Int
    ,type:String
    ,?message:ZulipMessage
  };

extern class ZulipQueues {
  function register(_:{
       ?apply_markdown:Bool
      ,?client_gravatar:Bool
      ,?event_types:Dynamic
      ,?all_public_streams:Bool
      ,?include_subscribers:Bool
      ,?fetch_event_types:Dynamic
      ,?narrow:Array<Array<String>>
    }):Promise<ZulipResult & {queue_id:String, last_event_id:Int}>;
  function deregister(_:{
      queue_id:String
    }):Promise<ZulipResult>;
}
