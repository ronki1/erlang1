%%%-------------------------------------------------------------------
%%% @author ron
%%% @copyright (C) 2017, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 10. Apr 2017 11:54
%%%-------------------------------------------------------------------
-module(midproj).
-author("ron").

%% API
-export([exp_to_bdd/2]).
-export([solve_bdd/2]).

solve_bdd(BddTree, List)->
  Map = listToMap(List,#{}),
  treeSearch(BddTree,Map).

%Searches the tree according to the values given in map
treeSearch({true},_Map)->true;
treeSearch({false},_Map)->false;
treeSearch(Tree,Map) ->
  CurrentAtom = element(1,Tree),
  AtomVal = maps:get(CurrentAtom,Map),
  LeftChild = element(2,Tree),
  RightChild = element(3,Tree),
  if
    AtomVal -> treeSearch(RightChild,Map);%if to go right
    true -> treeSearch(LeftChild,Map)
  end
.

exp_to_bdd(BoolFunc, Ordering)->
  %A = {'or', { {'or', { { 'and', { {'and', {{'not', x1},{'not', x2}} }, {'not', x3}} } , {'and',{x1,x2}} } } , {'and', {x2,x3}} }} ,
  %A = {'or',{ {'or',{ {'and',{ x1 , {'not', x2} }} , {'and',{ x2 , x3 }} }} , x3 }},
  Vars = remove_dups(findVars([],BoolFunc)),
  VarPerms = perms(Vars),
  %io:fwrite(lists:flatten(io_lib:format("~p \n\n", [VarPerms]))),
  OptimalTuple = getOptimal(BoolFunc,VarPerms,Ordering,-1,{}),
  element(1,OptimalTuple).

%gets the optimal tree according to the Ordering Var
getOptimal(_Exp,[],_Ordering,_CurrentMinOrdering,OptimalTuple)->OptimalTuple;
getOptimal(Exp,Perms,Ordering,CurrentMinOrdering,OptimalTuple)->%on first permutation CurrentMinOrdering should be negative
  CurrentTuple = getTreeAndParams(Exp,hd(Perms)),
  CurrentOrderingVal = maps:get(Ordering,element(2,CurrentTuple)),
  %io:fwrite(lists:flatten(io_lib:format("~p \n\n", [CurrentTuple]))), %prints all possible trees
  if
    CurrentMinOrdering<0-> getOptimal(Exp,tl(Perms),Ordering,CurrentOrderingVal,CurrentTuple);
    CurrentOrderingVal<CurrentMinOrdering-> getOptimal(Exp,tl(Perms),Ordering,CurrentOrderingVal,CurrentTuple);
    true -> getOptimal(Exp,tl(Perms),Ordering,CurrentMinOrdering,OptimalTuple)
  end.

%returns a tuple with tree representation and parameter map
getTreeAndParams(Exp, Vars) ->
  NewTree = buildInitialTree(Exp,#{},Vars),
  {NewTree,getTreeParams(NewTree,#{height=>0,numOfNodes=>0,numOfLeafs=>0},0)}.

%%test() ->
%%  %A = {'or',{ {'or',{ {'and',{ x1 , {'not', x2} }} , {'and',{ x2 , x3 }} }} , x3 }},
%%  A = {'or', { {'or', { { 'and', { {'and', {{'not', x1},{'not', x2}} }, {'not', x3}} } , {'and',{x1,x2}} } } , {'and', {x2,x3}} }} ,
%%  %A = {'and', {x1,{'not',x1}}},
%%  Vars = remove_dups(findVars([],A)),
%%  %Map = listToMap(Vars,#{}),Map,
%%  Tree = buildInitialTree(A,#{},Vars),
%%  Params = #{height=>0,numOfNodes=>0,numOfLeafs=>0},%height of only root is 0
%%  getTreeParams(Tree,Params,0).

buildInitialTree(Exp, Map, [])->{solveExp(Exp,Map)}; %builds the tree and minimizes it
buildInitialTree(Exp, Map, [H|T]) ->
  Left =  buildInitialTree(Exp, maps:put(element(1,H),false,Map),T),
  Right = buildInitialTree(Exp, maps:put(element(1,H),true,Map),T),
if
    Right=:= Left->Right;
    true-> {element(1,H),Left,Right}
end.

perms([]) -> [[]]; %finds all permutations of list
perms(L)  -> [[H|T] || H <- L, T <- perms(L--[H])].

%TODO change if x1,x2,x3 are not shown
%Traversal of the tree while updating Tree Parameters
getTreeParams(Tree,Params,Depth) when Tree=:={true} -> getTreeParams({false},Params,Depth);%when reached a leaf
getTreeParams(Tree,Params,Depth) when Tree=:={false} ->
  Inc1 = fun(V) -> V + 1 end,
  DepthFunc = fun(V) -> max(Depth,V) end,
  NewParams2 = funcOnMapElem(numOfLeafs,Inc1,Params),
  funcOnMapElem(height,DepthFunc,NewParams2);
%when reached a node
getTreeParams(Tree,Params,Depth)->
  Inc1 = fun(V) -> V + 1 end,
  NewParams = funcOnMapElem(numOfNodes,Inc1,Params),
  Left = element(2,Tree), Right = element(3,Tree),
  LeftParams = getTreeParams(Left,NewParams,Depth+1),
  getTreeParams(Right,LeftParams,Depth+1).

%run a function on a specific element of a map
funcOnMapElem(Key,Func,Map) ->
  OldVal = element(2,maps:find(Key,Map)),
  NewVal = Func(OldVal),
  maps:update(Key,NewVal,Map).

solveExp({'or',{L,R}},VarMap)->solveExp(L,VarMap) or solveExp(R,VarMap);%soelves the expression according to the values supplied in VarMap
solveExp({'and',{L,R}},VarMap)->solveExp(L,VarMap) and solveExp(R,VarMap);
solveExp({'not',R},VarMap)->not solveExp(R,VarMap);
solveExp(Val,VarMap) -> maps:get(Val, VarMap).


listToMap([],Map)->Map;%generates a map with atoms representing boolean operators, and their values
listToMap(List,Map)->listToMap(tl(List),maps:put(element(1,hd(List)), element(2,hd(List)), Map)).

remove_dups([])    -> []; %remove duplicates in list
remove_dups([H|T]) -> [H | [X || X <- remove_dups(T), X /= H]].

findVars(List,{'or',Exp}) -> findVars(List,Exp); %finds vars in expression
findVars(List,{'and',Exp}) -> findVars(List,Exp);
findVars(List,{'not',Exp}) when is_tuple(Exp) -> findVars(List,Exp);
findVars(_,{'not',Exp}) -> [{Exp,false}];
findVars(List,{A,B}) when is_tuple(A) and is_tuple(B)-> List++findVars(List,A)++findVars(List,B);
findVars(List,{A,B}) when not is_tuple(A) and is_tuple(B)-> List++[{A,false}]++findVars(List,B);
findVars(List,{A,B}) when is_tuple(A) and not is_tuple(B)-> List++findVars(List,A)++[{B,false}];
findVars(_,{A,B}) -> [{A,false},{B,false}];
findVars(_,A)->[{A,false}].