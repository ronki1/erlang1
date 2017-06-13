%%%-------------------------------------------------------------------
%%% @author ron
%%% @copyright (C) 2017, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 10. Jun 2017 16:57
%%%-------------------------------------------------------------------
-module(caller).
-author("ron").

%% API
-export([start/0]).
-define(Addr,'c2@127.0.0.1').

start() ->
  rpc:call(?Addr, callee,start,[]),
  spawn(fun()->loop(0) end).

loop(Num)->
  receive
    stat->
      io:fwrite("Messages Sent: ~p \n", [Num]),
      loop(Num);
    quit->
      rpc:call(?Addr, callee,call,[quit]),
      exit(kill);
    A->io:fwrite("sending: ~p \n", [A]),
      rpc:call(?Addr, callee,call,[A]),
      loop(Num+1)
  end.