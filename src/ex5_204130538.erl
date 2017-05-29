%%%-------------------------------------------------------------------
%%% @author ron
%%% @copyright (C) 2017, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 13. May 2017 13:19
%%%-------------------------------------------------------------------
-module(ex5_204130538).
-author("ron").

%% API
-export([ringA/2]).
-export([ringB/2]).
-export([mesh/3]).

ringA(N,M) ->
  BuidStart = get_timestamp(),
  HomeProcess = self(), %this process represents the "master" node
  NextPID = case N of
     Num when Num=:=1 -> self()!{self(),buildComplete},HomeProcess; %if there is only one node->no need to build a ring
     _ -> spawn(fun() -> processA(N-1,HomeProcess) end) %if there is more than one node
  end,
  receive
  {_Sender,buildComplete}->
    masterMessagePasser(NextPID,M,BuidStart) %when build is complete -> start acting as master
  end
.
masterMessagePasser(NextPID,0,StartTime)->%when finished receiving messages->terminate
  io:format("Time Took For Build and Passing (Micros): ~p~n", [get_timestamp() - StartTime]),
  NextPID!{self(),exit};%send termination throughout ring
masterMessagePasser(NextPID,M,StartTime) ->
  NextPID!{self(),message},
  receive
    {_Sender,message}->
      masterMessagePasser(NextPID,M-1,StartTime) %once a message is received -> recurrsive call
  end.


processA(1,HomeProcess)->%process builder for ring A. this case is executed when the final node in the ring is created
  HomeProcess!{self(),buildComplete},%notify home process that build is complete
  retransmitter(HomeProcess);%transmitt to home process(=beginning of the ring

processA(NextProcessesNum,HomeProcess) ->%case this is not the final node
  NextPID = case NextProcessesNum of
    Num when Num=:=1 -> HomeProcess;
    _ -> spawn(fun() -> processA(NextProcessesNum-1,HomeProcess) end)
  end,
  retransmitter(NextPID).%enter retransmittion mode

retransmitter(NextProcess) ->%retransmitter for retransmittion mode, after ring is created
  receive
    {_Sender,message}->% on message -> pass message and make a recurrsive call
      NextProcess ! {self(),message},
      retransmitter(NextProcess);
    {_Sender,exit} ->%on exit-> pass exit message and don't make a recurssive call
      NextProcess!{self(),exit};
    _ ->
      retransmitter(NextProcess)
  end.

ringB(N,M)->%ring B creation
  BuidStart = get_timestamp(),
  HomeProcess = self(),
  NextPID = case N of
    Num when Num=:=1 -> HomeProcess;%case there is one node in ring -> don't create any more nodes.
    _ -> processCreatorB(N-1,HomeProcess)%if there's more than one node
  end,
  masterMessagePasser(NextPID,M,BuidStart)
.

processB(NextPID) ->
  retransmitter(NextPID).%processB function

processCreatorB(0,HomeProcess) ->HomeProcess;%last process created
processCreatorB(N,HomeProcess) ->
  spawn(fun() -> processB(processCreatorB(N-1,HomeProcess)) end).%recurrsively create processes

%%%%%%

mesh(N,M,C) ->%create mesh
  ProcessMap = createMesh(N*N,N,C,#{},M,get_timestamp()), %create NxN processes and place them in a map
  updateProcessesWithMap(ProcessMap),  %notify all processes about the map
  maps:get(C, ProcessMap)!{self(),matrixCreated}%notify master build is finished
.

updateProcessesWithMap(ProcessMap) ->
  Fun = fun(_K,V,_AccIn) -> V!{self(),processMapUpdate,ProcessMap} end, %build finished nofifier
  maps:fold(Fun,0,ProcessMap)%send all processes that build is finished
.

createMesh(0,_N,_C,ProcessMap,_M,_StartTime) -> ProcessMap;%process building finished
createMesh(C,N,C,ProcessMap,M,StartTime)-> %case master
  createMesh(C-1,N,C,ProcessMap#{C=>spawn(fun() -> meshMasterProcess(N,M,N,#{},#{},(N*N-1)*M,StartTime,0) end)},M,StartTime);
createMesh(NumLeft,N,C,ProcessMap,M,StartTime)->%case transmitter
  createMesh(NumLeft-1,N,C,ProcessMap#{NumLeft=>spawn(fun() -> meshTransmitterProcess(NumLeft,N,M,C,#{},#{}) end)},M,StartTime).

meshMasterProcess(N,_M,C,ProcessMap,_MessageMap,ACKNum,StartTime,ACKNum) ->%received all acks
  io:format("Received: ~p Messages. Time Took For Passing Messages (Micros): ~p~n", [ACKNum,get_timestamp() - StartTime]),
  sendToDirsExcept(C,N,ProcessMap,{exit},none)
;

meshMasterProcess(N,M,C,ProcessMap,MessageMap,ACKNum,StartTime,ACKReceived) ->%Master havent received all ACKs
  receive
    {_Sender,processMapUpdate,Map} ->%processes created
      %io:format("MapUpdated: ~p~n", [Map]),
      meshMasterProcess(N,M,C,Map,MessageMap,ACKNum,StartTime,ACKReceived);
    {_Sender,matrixCreated}->%mesh build complete -> send initial message
      meshMasterInitialSend(N,M,C,ProcessMap),
      meshMasterProcess(N,M,C,ProcessMap,MessageMap,ACKNum,get_timestamp(),ACKReceived);%process function
    {_DIR,{messageReceived,MessageNum,ProcessNum}}->%ack received
      %io:format("Master MessageReceived: ~p procc: ~p ~n", [MessageNum,ProcessNum]),
      NewMessageMap = MessageMap#{{MessageNum,ProcessNum}=>a},
      %io:format("Master MapSize: ~p ~n", [maps:size(NewMessageMap)]),
      meshMasterProcess(N,M,C,ProcessMap,NewMessageMap,ACKNum,StartTime,maps:size(NewMessageMap));%update num of ACS received
    _ -> %new message messages should not be handled
      meshMasterProcess(N,M,C,ProcessMap,MessageMap,ACKNum,StartTime,ACKReceived)
  end.

meshTransmitterProcess(MyNum,N,M,C,ProcessMap,MessageMap) ->%none master processes
  receive
    {_Sender,processMapUpdate,Map} ->
      %io:format("MapUpdated: ~p~n", [Map]),
      meshTransmitterProcess(MyNum,N,M,C,Map,MessageMap);%mesh created
    {_DIR,{messageReceived,MessageNum,ProcessNum}}->%case ACK is recived
      case maps:is_key({messageReceived,MessageNum,ProcessNum},MessageMap) of
        false -> %if message hasnt already been received
          sendToDirsExcept(MyNum,N,ProcessMap,{messageReceived,MessageNum,ProcessNum},none),%send to neighboors
          meshTransmitterProcess(MyNum,N,M,C,ProcessMap,MessageMap#{{messageReceived,MessageNum,ProcessNum}=>a});
        _ ->%if message was already transmitted -> ignore
          meshTransmitterProcess(MyNum,N,M,C,ProcessMap,MessageMap)
      end;
    {_DIR,{newMessage,MessageNum}}->%case new message received
      case maps:is_key({newMessage,MessageNum},MessageMap) of
        false -> %if message hasnt already been received
          sendToDirsExcept(MyNum,N,ProcessMap,{newMessage,MessageNum},none),%retransmit
          sendToDirsExcept(MyNum,N,ProcessMap,{messageReceived,MessageNum,MyNum},none),%send ACK

          meshTransmitterProcess(MyNum,N,M,C,ProcessMap,MessageMap#{{newMessage,MessageNum}=>a});
        _ ->
          meshTransmitterProcess(MyNum,N,M,C,ProcessMap,MessageMap)
      end;
    {_DIR,{exit}}->
          sendToDirsExcept(MyNum,N,ProcessMap,{exit},none);%on exit do not reccurse
    _ -> %messages that should not be handled
      meshTransmitterProcess(MyNum,N,M,C,ProcessMap,MessageMap)
end.

meshMasterInitialSend(_N,0,_C,_ProcessMap) -> initialSendFinished;%all messages sent
meshMasterInitialSend(N,M,C,ProcessMap) ->%send new message to all directions
  sendUpwards(C,N,ProcessMap,{newMessage,M}),
  sendDownwards(C,N,ProcessMap,{newMessage,M}),
  sendRight(C,N,ProcessMap,{newMessage,M}),
  sendLeft(C,N,ProcessMap,{newMessage,M}),
  meshMasterInitialSend(N,M-1,C,ProcessMap)
.
sendToDirsExcept(MyNum,N,ProcessMap,Message,none) ->%send to all directions
  sendUpwards(MyNum,N,ProcessMap,Message),
  sendDownwards(MyNum,N,ProcessMap,Message),
  sendRight(MyNum,N,ProcessMap,Message),
  sendLeft(MyNum,N,ProcessMap,Message);
sendToDirsExcept(MyNum,N,ProcessMap,Message,up) ->%send to all directions except upwards
  sendDownwards(MyNum,N,ProcessMap,Message),
  sendRight(MyNum,N,ProcessMap,Message),
  sendLeft(MyNum,N,ProcessMap,Message);
sendToDirsExcept(MyNum,N,ProcessMap,Message,down) ->%send to all directions except downwards
  sendUpwards(MyNum,N,ProcessMap,Message),
  sendRight(MyNum,N,ProcessMap,Message),
  sendLeft(MyNum,N,ProcessMap,Message);
sendToDirsExcept(MyNum,N,ProcessMap,Message,left) ->%send to all directions except left
  sendDownwards(MyNum,N,ProcessMap,Message),
  sendRight(MyNum,N,ProcessMap,Message),
  sendUpwards(MyNum,N,ProcessMap,Message);
sendToDirsExcept(MyNum,N,ProcessMap,Message,right) ->%send to all directions except right
  sendDownwards(MyNum,N,ProcessMap,Message),
  sendUpwards(MyNum,N,ProcessMap,Message),
  sendLeft(MyNum,N,ProcessMap,Message).

sendUpwards(MyNum,N,ProcessMap,Message)->
  if
    MyNum-N >= 1 -> maps:get(MyNum-N, ProcessMap)!{up,Message};%if can pass upwards
    true ->cantSend
  end
.
sendDownwards(MyNum,N,ProcessMap,Message)->
  if
    MyNum+N =< N*N -> maps:get(MyNum+N, ProcessMap)!{down,Message};%if can pass upwards
    true ->cantSend
  end
.
sendRight(MyNum,N,ProcessMap,Message)->
  if
    (MyNum rem N) =/= 0 -> maps:get(MyNum+1, ProcessMap)!{right,Message};%if can pass upwards
    true ->cantSend
  end
.
sendLeft(MyNum,N,ProcessMap,Message)->
  if
    (MyNum rem N) =/= 1 -> maps:get(MyNum-1, ProcessMap)!{left,Message};%if can pass upwards
    true ->cantSend
  end
.

get_timestamp() ->
  os:system_time(1000000).