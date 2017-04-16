%%%-------------------------------------------------------------------
%%% @author ron
%%% @copyright (C) 2017, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 29. Mar 2017 13:42
%%%-------------------------------------------------------------------
-module(ex2_204130538).
-author("ron").

%% API
-export([findKelem/2]).
-export([reverse/1]).
-export([deleteKelem/2]).
-export([addKelem/3]).
-export([union/2]).

findKelem([],_K)-> notFound; %case went through all list and not found
findKelem([H|_T],1)-> H;%case found element
findKelem([_H|T],K)->findKelem(T,K-1).

reverse([]) -> [];%special case
reverse(List)->reverseHelper(List,[],myLength(List,0),myLength(List,0)).%call to reverse helper with new parameters that will be used for iterations
reverseHelper(_List,NewList,0,_Size)->NewList;%end case after iterating over all elements
reverseHelper(List,NewList,K,Size)->reverseHelper(List,[findKelem(List,Size-K+1)|NewList],K-1,Size).%call to reverseHelper, decreasing the K count and adding new element to head.

deleteKelem([],_)->[];
deleteKelem(List,Elem)->deleteKelemHelper(List,Elem,myLength(List,0),[]).
deleteKelemHelper(_List,_Elem,0,NewList)->NewList;%print list
deleteKelemHelper(List,Elem,K,NewList)->deleteKelemHelper(List,Elem,K-1,deleteKelemBuilder(NewList,Elem,findKelem(List,K),findKelem(List,K)=:=Elem)).
deleteKelemBuilder(NewList,_Elem,_CurrentElem,true)-> NewList;%current elelment and ELement are equal) -> don't add.
deleteKelemBuilder(NewList,_Elem,CurrentElem,_Subt)->[CurrentElem|NewList]. %builds the original list with current element

addKelem(List,1,Elem)-> [Elem|List];
addKelem(List,K,Elem)-> addKelemHelper(List,myLength(List,0),K,Elem,[],1,myLength(List,0)+1 =:= K).
addKelemHelper(List,Index,K,Elem,NewList,_Subt,true)->addKelemHelper(List,Index,K+2,Elem,[Elem|NewList],1,1);%in case K is biggre than length
addKelemHelper(_List,0,_K,_Elem,NewList,_Subt,_NewElement)->NewList;%in case finished building
addKelemHelper(List,Index,K,Elem,NewList,0,_NewElement)->addKelemHelper(List,Index,K+2,Elem,[Elem|NewList],1,1);%in case needs to add an element
addKelemHelper(List,Index,K,Elem,NewList,_Subt,_NewElement)->addKelemHelper(List,Index-1,K,Elem,[findKelem(List,Index)|NewList],Index-K,1).

union(List1,List2)-> A= unionRemoveInstances(List1,List2,myLength(List2,0)),%remove duplicates
  unionBuilder(A,List2,myLength(A,0),myLength(List2,0),right,[]).%unite without duplicates

unionRemoveInstances(RemoveFrom,_CompareWith,0)->RemoveFrom;
unionRemoveInstances(RemoveFrom,CompareWith,K)->unionRemoveInstances(deleteKelem(RemoveFrom,findKelem(CompareWith,K)),CompareWith,K-1).%remove all occurences of CompareWith elements in Remove From

%unionBuilder first adds List2 to NewList, and then adds List1
unionBuilder(List1,List2,K1,0,right,NewList)-> unionBuilder(List1,List2,K1,0,left,NewList);
unionBuilder(List1,List2,K1,K2,right,NewList)-> unionBuilder(List1,List2,K1,K2-1,right,[findKelem(List2,K2)|NewList]);
unionBuilder(_List1,_List2,0,_K2,left,NewList)-> NewList;
unionBuilder(List1,List2,K1,K2,left,NewList)-> unionBuilder(List1,List2,K1-1,K2,right,[findKelem(List1,K1)|NewList]).

myLength([],K)->K;%custom function to use length
myLength([_H|T],K)->myLength(T,K+1).