%%%-------------------------------------------------------------------
%%% @author ron
%%% @copyright (C) 2017, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 05. Apr 2017 16:17
%%%-------------------------------------------------------------------
-module(ex3_204130538).
-author("ron").

%% API
-export([sortLC/1]).
-export([sortPM/1]).
-export([sortLM/1]).

-export([matMult/1]).

-export([addKElem/3]).

-export([fiboR/1]).
-export([fiboT/1]).

-export([even/1]).

-export([mSort/1]).

-export([qSort/1]).

sortLC(List)-> qSort([X || X <- List, mod(X, 3) =:= 0]) ++ qSort([X || X <- List, mod(X, 3) =:= 1]) ++qSort([X || X <- List, mod(X, 3) =:= 2]).%concat lists

sortPM([])->[];
sortPM(List)->pmHelper(List,[],[],[],mod(hd(List),3),length(List)). %send list to helper for pattern matching the mod of the head

pmHelper([HList|_TList],Mod0,Mod1,Mod2,0,1)->qSort([HList|Mod0])++qSort(Mod1)++qSort(Mod2);
pmHelper([HList|_TList],Mod0,Mod1,Mod2,1,1)->qSort(Mod0)++qSort([HList|Mod1])++qSort(Mod2);
pmHelper([HList|_TList],Mod0,Mod1,Mod2,2,1)->qSort(Mod0)++qSort(Mod1)++qSort([HList|Mod2]);
pmHelper([HList|TList],Mod0,Mod1,Mod2,0,Iteration)->pmHelper(TList,[HList|Mod0],Mod1,Mod2,mod(hd(TList),3),Iteration-1);
pmHelper([HList|TList],Mod0,Mod1,Mod2,1,Iteration)->pmHelper(TList,Mod0,[HList|Mod1],Mod2,mod(hd(TList),3),Iteration-1);
pmHelper([HList|TList],Mod0,Mod1,Mod2,2,Iteration)->pmHelper(TList,Mod0,Mod1,[HList|Mod2],mod(hd(TList),3),Iteration-1).


sortLM(List)->lists:sort(lists:filter(fun(X) -> mod(X, 3) =:= 0 end, List)) ++ lists:sort(lists:filter(fun(X) -> mod(X, 3) =:= 1 end, List)) ++ lists:sort(lists:filter(fun(X) -> mod(X, 3) =:= 2 end, List)).

mod(A, B) when A > 0 -> A rem B; %custom mod function for negative numbers
mod(A, B) when A < 0 -> mod(A+B, B);
mod(0, _) -> 0.


multRows([],[],Acc) -> Acc;
multRows([VecAH|VecAT],[VecBH|VecBT],Acc) -> multRows(VecAT,VecBT,Acc + VecAH*VecBH). %multiplies vectors as dot product

matMult([]) -> [];
matMult(Matrix)-> ColsMat = createCols(Matrix), [ [multRows(A, B,0) || B <- ColsMat ] || A <- Matrix]. %creates rows of transpose and multiplies as dot product

createCols([]) -> [];%transposes the matrix and creates vectors to be multiplied
createCols([[]|_])->[];
createCols(Mat)->[ [Heads || [Heads|_]<-Mat] | createCols( [ LeftTail || [_|LeftTail]<-Mat ])].

%adds elem to k'th place in List
addKElem(List,K,Elem)->
    case K of
      N when N=<1-> [Elem|List];
      N when N>length(List) -> List ++ [Elem];
      _Else -> [hd(List) | addKElem(tl(List),K-1,Elem)]
    end
  .

even(List)->evenHelper(evenHelper(List,[]),[]). %returns even numvers in list by order of appearance

evenHelper([],NewList)-> NewList;
evenHelper([LH|LT],NewList) when LH rem 2 =:= 0 ->evenHelper(LT,[LH|NewList]);
evenHelper([_LH|LT],NewList)->evenHelper(LT,NewList).

fiboR(1)->1;
fiboR(2)->1;
fiboR(N)->fiboR(N-1) + fiboR(N-2). %recurrsive fibonacci

fiboT(1)->1; %tail recurrsion fibonacci
fiboT(2)->1;
fiboT(N)->fiboTHelper(1,1,N-2).
fiboTHelper(A,_,0)->A;
fiboTHelper(A,B,N)->fiboTHelper(A+B,A,N-1).

mSort([]) -> []; %merge sort
mSort([E]) -> [E];
mSort(List) ->
  {A, B} = lists:split(trunc(length(List)/2), List),
  merge(mSort(A), mSort(B)).

merge(Left, []) -> Left;
merge([], Right) -> Right;
merge([HLeft|TLeft], [HRight|TRight]) ->
  if
    HLeft < HRight -> [HLeft | merge(TLeft, [HRight|TRight])];
    true -> [HRight | merge([HLeft|TLeft], TRight)]
  end.

%quick sort
qSort([Pvt|T]) ->
  qSort([ X || X <- T, X < Pvt]) ++
    [Pvt] ++
    qSort([ X || X <- T, X >= Pvt]);
qSort([]) -> [].

