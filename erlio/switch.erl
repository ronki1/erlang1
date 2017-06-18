-module(switch).

-export([start/0]).


start() ->
  spawn(fun start1/0).

start1() ->
  gen_udp:open(7777,[binary, {active,true}]),
  loop_udp().


loop_udp() ->
  receive
    {udp,_,IP,Port,<<0:8,X:32/signed-integer,Y:32/signed-integer>>} -> % x,y
      io:format("move ~p:~p ~p,~p~n",[IP,Port,X,Y]),
      gen_server:call(main_server,{movePlayer,{IP,Port},X,Y}),
      loop_udp();
    {udp,_,IP,Port,<<1:8,N/binary>>} -> % register
      Name = binary_to_list(N),
      io:format("register ~p:~p ~p~n",[IP,Port,Name]),
      gen_server:call(main_server,{register,{IP,Port},Name}),
      loop_udp()
  end.