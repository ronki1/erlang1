-module(s).
-export([start_udp/1]).

start_udp(Port) ->
	gen_udp:open(Port,[binary,{active,true}]),
	loop_udp().

loop_udp() ->
	receive
	M -> 
		io:format("received: ~p~n", [M]),
		loop_udp();
	{_,_,_,_,<<R:32/signed-integer,A:32/signed-integer>>} ->
		io:format("received: ~p,~p~n", [R,A]),
		loop_udp()
	end.
