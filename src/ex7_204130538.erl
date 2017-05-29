%%%-------------------------------------------------------------------
%%% @author ron
%%% @copyright (C) 2017, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 28. May 2017 18:26
%%%-------------------------------------------------------------------
-module(ex7_204130538).
-author("ron").

%% API
-export([steady/1]).

steady(F) ->
  try F() of
    Ret->A={get_timestamp(),success,Ret},log(A),A %return and log successful results
  catch
    error:Error -> A= {get_timestamp(),error,Error},log(A),A;%return and log errors
    exit:Exit -> B={get_timestamp(),exit,Exit},log(B),B;%return and log exits
    Throw->C={get_timestamp(),throw,Throw},log(C),C%return and log throws
  end
.

log(M) ->
  file:write_file("myLog_204130538.elog", io_lib:fwrite("~p\n", [M]),[append]).%append log to file





get_timestamp() ->
os:system_time(1000000). %return time in micros