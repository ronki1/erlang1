%%%-------------------------------------------------------------------
%%% @author ron
%%% @copyright (C) 2017, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 12. Jun 2017 17:56
%%%-------------------------------------------------------------------
-module(callee).
-author("ron").

%% API
-export([start/0,call/1,quit/0]).
start()->
  register(main_process,spawn(fun()->loop()end)).

loop()->
  receive
    quit->
      exit(kill);
    A ->
      io:fwrite("Received: ~p \n", [A]),
      loop()
  end.

call(Msg)->
  main_process!Msg
  %io:fwrite("Received: ~p \n", [Msg])
.

quit() ->
  exit(kill).