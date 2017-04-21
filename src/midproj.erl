%%%-------------------------------------------------------------------
%%% @author ron kotlarsky
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


%%requested function, receives a BDD tree and a list of values for every Boolean variable that’s
%%used in the Boolean function and returns the result of that function, according to the given BDD tree.
solve_bdd(BddTree, List)->
  Map = listToMap(List,#{}),
  treeSearch(BddTree,Map).

%Searches the tree according to the values given in map
treeSearch({true},_Map)->true; %case reached a leaf
treeSearch({false},_Map)->false;%case reached a leaf
treeSearch(Tree,Map) ->
  CurrentAtom = element(1,Tree),
  AtomVal = maps:get(CurrentAtom,Map),
  LeftChild = element(2,Tree),
  RightChild = element(3,Tree),
  if
    AtomVal -> treeSearch(RightChild,Map);%if to go right
    true -> treeSearch(LeftChild,Map) %if to go left
  end
.

exp_to_bdd(BoolFunc, Ordering)->
  %A = {'or', { {'or', { { 'and', { {'and', {{'not', x1},{'not', x2}} }, {'not', x3}} } , {'and',{x1,x2}} } } , {'and', {x2,x3}} }} ,
  %A = {'or',{ {'or',{ {'and',{ x1 , {'not', x2} }} , {'and',{ x2 , x3 }} }} , x3 }},
  %A1={'and',{{'and',{{'not',x2},x1}},x3}},
  %B={'not',{'and' , { x1, {'and' ,{{'not', x3},{'or', {{'not', x4},x2}}}}}}},
  %C={'not',{'and',{x4,x1}}},
  %Tot = {'or', {C, {'or', {A1,B}}}},
  StartTimeStamp = get_timestamp(),
  Vars = remove_dups(findVars([],BoolFunc)),
  VarPerms = perms(Vars),
  %io:fwrite(lists:flatten(io_lib:format("~p \n\n", [VarPerms]))),
  OptimalTuple = getOptimal(BoolFunc,VarPerms,Ordering,-1,{}),
  %io:fwrite(lists:flatten(io_lib:format("~p \n\n", [element(1,OptimalTuple)]))),
  io:fwrite(lists:flatten(io_lib:format("Execution Time (millis) ~p \n\n", [get_timestamp()-StartTimeStamp]))),
  element(1,OptimalTuple).

%gets the optimal tree according to the Ordering Var
getOptimal(_Exp,[],_Ordering,_CurrentMinOrdering,OptimalTuple)->OptimalTuple;%end of permutations reached -> return the result
getOptimal(Exp,Perms,Ordering,CurrentMinOrdering,OptimalTuple)->%on first permutation CurrentMinOrdering should be negative
  CurrentTuple = getTreeAndParams(Exp,hd(Perms)),
  CurrentOrderingVal = maps:get(Ordering,element(2,CurrentTuple)),
  %io:fwrite(lists:flatten(io_lib:format("~p \n\n", [CurrentTuple]))), %prints all possible trees
  if
    CurrentMinOrdering<0-> getOptimal(Exp,tl(Perms),Ordering,CurrentOrderingVal,CurrentTuple); %if first iteration
    CurrentOrderingVal<CurrentMinOrdering-> getOptimal(Exp,tl(Perms),Ordering,CurrentOrderingVal,CurrentTuple);%if found optimal
    true -> getOptimal(Exp,tl(Perms),Ordering,CurrentMinOrdering,OptimalTuple) %if not found optimal
  end.

%returns a tuple with tree representation and parameter map
getTreeAndParams(Exp, Vars) ->
  NewTree = buildInitialTree(Exp,#{},Vars),
  {NewTree,getTreeParams(NewTree,#{treeHeight=>0,numOfNodes=>0,numOfLeafs=>0},0)}.

buildInitialTree(Exp, Map, [])->{solveExp(Exp,Map)}; %builds the tree and minimizes it
buildInitialTree(Exp, Map, [H|T]) ->
  Left =  buildInitialTree(Exp, maps:put(element(1,H),false,Map),T),
  Right = buildInitialTree(Exp, maps:put(element(1,H),true,Map),T),
if
    Right=:= Left->Right; %if it is possible to reduce order -> change current node with one of its children
    true-> {element(1,H),Left,Right} %if impossible to reduce order -> add children to current node
end.

perms([]) -> [[]]; %finds all permutations of list
perms(L)  -> [[H|T] || H <- L, T <- perms(L--[H])].

%Traversal of the tree while updating Tree Parameters
getTreeParams(Tree,Params,Depth) when Tree=:={true} -> getTreeParams({false},Params,Depth);%when reached a leaf
getTreeParams(Tree,Params,Depth) when Tree=:={false} ->
  Inc1 = fun(V) -> V + 1 end,
  DepthFunc = fun(V) -> max(Depth,V) end,
  NewParams2 = funcOnMapElem(numOfLeafs,Inc1,Params),
  funcOnMapElem(treeHeight,DepthFunc,NewParams2);
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


%solves the expression according to the values supplied in VarMap
solveExp({'or',{L,R}},VarMap)->solveExp(L,VarMap) or solveExp(R,VarMap);
solveExp({'and',{L,R}},VarMap)->solveExp(L,VarMap) and solveExp(R,VarMap);
solveExp({'not',R},VarMap)->not solveExp(R,VarMap);%unitary operator
solveExp(Val,VarMap) -> maps:get(Val, VarMap).


listToMap([],Map)->Map;%generates a map with atoms representing boolean operators, and their values
listToMap(List,Map)->listToMap(tl(List),maps:put(element(1,hd(List)), element(2,hd(List)), Map)).

remove_dups([])    -> []; %remove duplicates in list
remove_dups([H|T]) -> [H | [X || X <- remove_dups(T), X /= H]].

findVars(List,{'or',Exp}) -> findVars(List,Exp); %finds vars in expression
findVars(List,{'and',Exp}) -> findVars(List,Exp);
findVars(List,{'not',Exp}) when is_tuple(Exp) -> findVars(List,Exp);
findVars(_,{'not',Exp}) -> [{Exp,false}];
findVars(List,{A,B}) when is_tuple(A) and is_tuple(B)-> List++findVars(List,A)++findVars(List,B);%when left and right are tuples
findVars(List,{A,B}) when not is_tuple(A) and is_tuple(B)-> List++[{A,false}]++findVars(List,B);%when only right val is tuple
findVars(List,{A,B}) when is_tuple(A) and not is_tuple(B)-> List++findVars(List,A)++[{B,false}];%when only left val is tuple
findVars(_,{A,B}) -> [{A,false},{B,false}];
findVars(_,A)->[{A,false}].

%get the current timestamp in milliseconds
get_timestamp() ->
  {Mega, Sec, Micro} = os:timestamp(),
  (Mega*1000000 + Sec)*1000 + round(Micro/1000).