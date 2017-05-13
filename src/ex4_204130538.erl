%%%-------------------------------------------------------------------
%%% @author ron
%%% @copyright (C) 2017, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 29. Apr 2017 10:36
%%%-------------------------------------------------------------------
-module(ex4_204130538).
-author("ron").

%% API
-export([flatten/1]).
-export([smaller/2]).
-export([replace/3]).
-export([mapSub/2]).

flatten(List) -> lists:flatten(List). %as yehuda said-> whenever an existing funtion is available - use it.

smaller(List, Thr) -> [X || X <- List, X =< Thr]. %return all elements smaller\equal than Thr

replace(List, Old, New) -> replaceHelper(List,Old,New,[]).

replaceHelper([],_,_,NewList) -> lists:reverse(NewList);
replaceHelper([H|T],Old,New,NewList) when H =:=Old -> replaceHelper(T,Old,New,[New|NewList]);%remove element (also achievable without guard).
replaceHelper([H|T],Old,New,NewList) -> replaceHelper(T,Old,New,[H|NewList]).%dont remove item

%implementation of map sub is also possible by defining a functio without guards and cases, I chose this way however...
mapSub(List1,List2)->
  {_,Sm} = lists:mapfoldl(fun(X, Sum) ->
    case hd(Sum)=<length(List2) of
       true->   case X=:=lists:nth(hd(Sum),List2) of
            true -> {X, [hd(Sum)+1]++tl(Sum)};%alteration of list is needed
            _ -> {X, Sum++[X]} end;%add value and do not remove it
      _-> {X,Sum++[X]} %case all elements needed to remove have been removed
    end
    end,
    [1], List1),
  tl(Sm).%return value without List2 indicator