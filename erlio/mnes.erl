%%%-------------------------------------------------------------------
%%% @author ron
%%% @copyright (C) 2017, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 17. Jun 2017 16:37
%%%-------------------------------------------------------------------
-module(mnes).
-author("ron").

-include("foodDB.hrl").

%% API
-export([init_db/0,print_db/0,insert_food/2,remove_food/1,getFoods/0,insert_player/1,getPlayer/1,getPlayers/0,getPlayerById/1,grow_player_db/1]).

init_db() ->
  mnesia:delete_table(food),
  mnesia:delete_table(player),
  mnesia:delete_schema([node()]),
  mnesia:create_schema([node()]),
  mnesia:start(),
  mnesia:create_table(food,
    [{attributes, record_info(fields, food)}]),
  mnesia:create_table(player,
    [{attributes, record_info(fields, player)}])
.

print_db() ->
  CatchAll = [{'_',[],['$_']}],
  mnesia:dirty_select(food, CatchAll)
.

getFoods()->
  CatchAll = [{'_',[],['$_']}],
  mnesia:dirty_select(food, CatchAll)
.

getPlayers()->
  CatchAll = [{'_',[],['$_']}],
  mnesia:dirty_select(player, CatchAll)
.

getPlayer(PID) ->
  [{P,X,Y,R,ID,Name} || {player,P,X,Y,R,ID,Name} <- getPlayers(), P =:= PID]
.
getPlayerById(SearchId) ->
  [{P,X,Y,R,ID,Name} || {player,P,X,Y,R,ID,Name} <- getPlayers(), ID =:= SearchId]
.


insert_food(PID, {X,Y,R}) ->
  Fun = fun() ->
    FoodInfo = #food{pid = PID, x = X,y=Y,radius = R},
    mnesia:write(FoodInfo)
  end,
  mnesia:transaction(Fun)
.

insert_player({PID,X,Y,R,ID,Name}) ->
  Fun = fun() ->
    PlayerInfo = #player{pid = PID, x = X,y=Y,radius = R,id=ID,name=Name},
    mnesia:write(PlayerInfo)
  end,
  mnesia:transaction(Fun)
.

grow_player_db({PID,Dr}) ->
  F = fun() ->
  [E] = mnesia:read(player,PID , write),
  Radius = E#player.radius + Dr,
  New = E#player{radius = Radius},
  mnesia:write(New)
  end,
mnesia:transaction(F).

remove_food(PID)->
  Fun = fun()->
    mnesia:delete({food, PID})
  end,
  mnesia:transaction(Fun)
.