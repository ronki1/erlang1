%%%-------------------------------------------------------------------
%%% @author ron
%%% @copyright (C) 2017, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 12. Jun 2017 18:20
%%%-------------------------------------------------------------------
-module(ex8_204130538).
-author("ron").

%% API
-export([startChat/1,start_callee/0,call_callee/1,steadyLink/1,steadyMon/1]).

startChat(Addr)->%start caller
  start_caller(Addr).

start_caller(Addr) ->
  rpc:call(Addr, ex8_204130538,start_callee,[]),%start callee
  spawn(fun()->loop_caller(Addr,0) end).%spawn loop

loop_caller(Addr,Num)->
  receive
    stat->
      io:fwrite("Messages Sent\Received: ~p \n", [Num]),
      loop_caller(Addr,Num); %reccursive call
    quit->
      rpc:call(Addr, ex8_204130538,call_callee,[quit]),%quit
      exit(kill);
    A->io:fwrite("Caller Sending: ~p \n", [A]),
      rpc:call(Addr, ex8_204130538,call_callee,[A]),
      loop_caller(Addr,Num+1)%recurssive call, add num
  end.

start_callee()->
  case whereis(main_process) of %if process is registered-> dont register anything
    undefined -> register(main_process, spawn(fun() -> loop_callee() end))
  end.

loop_callee()->
  receive
    quit->
      exit(kill);%quit
    A ->
      io:fwrite("Callee Received: ~p \n", [A]),%print received
      loop_callee()
  end.

call_callee(Msg)->
  main_process!Msg%calle->send to loop receive
.

steadyLink(F) ->
  P = spawn_link(F),
  receive
    _ -> ok
  after 5000->
    P %print pid if havent died
  end
.

steadyMon(F)->
  spawn_monitor(fun() -> try F() of			%send exceptions
                           _	-> normal%if no exceptions-> ret normal
                         catch
                           error:_Error 	-> exit(error);%return error
                           exit:_Exit	-> exit(exit);%return exit
                           throw:_Throw	-> exit(throw)
                         end
                end),
  receive
    {_,_,_,PID,normal}->io:fwrite("Normal Termination of process ~p was detected \n", [PID]);
    {_,_,_,PID,Reason}->io:fwrite("An exception in process ~p was detected: ~p \n", [PID,Reason])
  end
.