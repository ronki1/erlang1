-module(player).

-behaviour(gen_server).
-export([start/1]).
%% gen_server callbacks
-export([init/1, handle_call/3, handle_cast/2, handle_info/2,
  terminate/2, code_change/3]).
-compile(export_all).
-define(SERVER, ?MODULE).

-import(mnes,[init_db/0,print_db/0,insert_food/2,remove_food/1,getFoods/0,grow_player_db/1]).

start(Args) -> gen_server:start_link(?MODULE, Args, []).
stop()  -> gen_server:call(?MODULE, stop).

init(Args) ->
  {X,Y,R,ID,Name} = Args,
  {ok,{X,Y,R,ID,Name}}
.

dummy(Dx,Dy,Dr)->
  gen_server:call(?MODULE,{movePlayer,Dx,Dy,Dr})
.

handle_call({movePlayer,Dx,Dy,Dr}, _From, Tab) ->
  {X,Y,R,ID,Name} = Tab,
  FoodsEaten = gen_server:call(food_server,{playerMoved,X+Dx,Y+Dy,R+Dr}),
  io:fwrite("Player moved to {~p,~p} \n",[X+Dx,Y+Dy]),
  case FoodsEaten of
    []->{reply, playerMoved, {X+Dx,Y+Dy,R+Dr,ID,Name}};
    A->NewDelta = growPlayer(A,0),{reply, playerMoved, {X+Dx,Y+Dy,R+NewDelta,ID,Name}} %TODO! notify graphics
  end
;

handle_call(stop, _From, Tab) ->
  {stop, normal, stopped, Tab}.
handle_cast(_Msg, State) ->{reply, ok, State}.
handle_info(_Info, State) -> {noreply, State}.
terminate(_Reason, _State) -> ok.
code_change(_OldVsn, State, _Extra) -> {ok, State}.

growPlayer([],Sum)->
  grow_player_db({self(),Sum}),
  Sum;
growPlayer([H|T],Sum)->
  {_X,_Y,R}=H,
  growPlayer(T,Sum+R)
.