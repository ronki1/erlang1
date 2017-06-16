-module(food).

-behaviour(gen_server).
-export([start/0]).
%% gen_server callbacks
-export([init/1, handle_call/3, handle_cast/2, handle_info/2,
  terminate/2, code_change/3,dummy/3]).
-compile(export_all).
-define(SERVER, ?MODULE).

start() -> gen_server:start_link({local, ?SERVER}, ?MODULE, [], []).
stop()  -> gen_server:call(?MODULE, stop).

new_account(Who)      -> gen_server:call(?MODULE, {new, Who}).
deposit(Who, Amount)  -> gen_server:call(?MODULE, {add, Who, Amount}).
withdraw(Who, Amount) -> gen_server:call(?MODULE, {remove, Who, Amount}).

init([]) ->
  ETS = ets:new(foodTable, [set, named_table]),
  ets:insert(foodTable, {xyr, {0,0,1}}),
  {ok, ETS}
.

dummy(X,Y,R)->
  gen_server:call(?MODULE,{playerMoved,1,R,X,Y})
.

handle_call({playerMoved,PlayerPid,PlayerRadius,PlayerX,PlayerY}, _From, Tab) ->
  [{xyr,{X,Y,Radius}}|_] = ets:lookup(Tab,xyr),
  %{xyr,{X,Y,Radius}} =
  %Reply=ets:lookup(Tab,xyr),
  Distance = math:sqrt(math:pow(PlayerX-X,2)+math:pow(PlayerY-Y,2)),
  Reply =Distance>PlayerRadius-Radius,
  {reply, Reply, Tab};

handle_call(stop, _From, Tab) ->
  {stop, normal, stopped, Tab}.
handle_cast(_Msg, State) -> {noreply, State}.
handle_info(_Info, State) -> {noreply, State}.
terminate(_Reason, _State) -> ok.
code_change(_OldVsn, State, _Extra) -> {ok, State}.

    