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
-export([init_db/0,print_db/0,insert_food/2,remove_food/1,getFoods/0]).

init_db() ->
  mnesia:delete_table(food),
  mnesia:delete_schema([node()]),
  mnesia:create_schema([node()]),
  mnesia:start(),
  mnesia:create_table(food,
    [{attributes, record_info(fields, food)}])
.

print_db() ->
  CatchAll = [{'_',[],['$_']}],
  mnesia:dirty_select(food, CatchAll)
.

getFoods()->
  CatchAll = [{'_',[],['$_']}],
  mnesia:dirty_select(food, CatchAll)
.

insert_food(PID, {X,Y,R}) ->
  Fun = fun() ->
    FoodInfo = #food{pid = PID, x = X,y=Y,radius = R},
    mnesia:write(FoodInfo)
  end,
  mnesia:transaction(Fun)
.

remove_food(PID)->
  Fun = fun()->
    mnesia:delete({food, PID})
  end,
  mnesia:transaction(Fun)
.