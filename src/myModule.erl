%%%-------------------------------------------------------------------
%%% @author ron
%%% @copyright (C) 2017, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 27. Mar 2017 08:15
%%%-------------------------------------------------------------------
-module(myModule).
-author("ron").

%% API
-export([hello/0]).
-export([calc/3]).

hello() -> io:fwrite("Hello\n").

calc(plus,A,B) -> A+B;
calc(substraction,A,B)->A-B;
calc(multiply,A,B)->A*B;
calc(division,_,0)->error_division_0;
calc(division,A,B)->A/B;
calc(pow,A,B) ->calcPow(A,A,B).

calcPow(Sum,_B,1)-> Sum;
calcPow(Sum,A,Count)->calcPow(Sum*A,A,Count-1).
