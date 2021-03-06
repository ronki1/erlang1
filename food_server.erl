-module(food_server).

-behaviour(gen_server).
-export([start/0]).
%% gen_server callbacks
-export([init/1, handle_call/3, handle_cast/2, handle_info/2,
  terminate/2, code_change/3]).
-compile(export_all).
-define(SERVER, ?MODULE).

-import(mnes,[init_db/0,print_db/0,insert_food/2,remove_food/1,getFoods/0]).

start() -> gen_server:start_link({local, ?SERVER}, ?MODULE, [], []).
stop()  -> gen_server:call(?MODULE, stop).

init([]) ->
  init_db(),
  generateFoods(5),
  {ok,tab}
.

dummy(X,Y,R)->
  gen_server:call(?MODULE,{playerMoved,1,X,Y,R})
.

handle_call({playerMoved,PlayerPid,PlayerX,PlayerY,PlayerRadius}, _From, Tab) ->
  DeletedPIDs = notifyFoods(getFoods(),{playerMoved,1,PlayerX,PlayerY,PlayerRadius},[]),
  {reply, DeletedPIDs, Tab};

handle_call(stop, _From, Tab) ->
  {stop, normal, stopped, Tab}.
handle_cast(_Msg, State) ->{reply, ok, State}.
handle_info(_Info, State) -> {noreply, State}.
terminate(_Reason, _State) -> ok.
code_change(_OldVsn, State, _Extra) -> {ok, State}.

generateFoods(0)->
  ok;
generateFoods(Num)->
  X=random:uniform(100),
  Y=random:uniform(100),
  {ok,PID} = food:start({X,Y,2}),
  insert_food(PID,{X,Y,2}),
  generateFoods(Num-1)
.

notifyFoods([],_Message,DeletedPIDs)->
  DeletedPIDs
;
notifyFoods([H|T],Message,DeletedPIDs) ->
  {food,PID,X,Y,R} = H,
  Reply = gen_server:call(PID,Message),
  case Reply of
    true->%if eaten
      remove_food(PID),
      gen_server:call(PID,stop),
      notifyFoods(T,Message,[{X,Y,R}|DeletedPIDs]);
    _ ->  notifyFoods(T,Message,DeletedPIDs)
  end
.