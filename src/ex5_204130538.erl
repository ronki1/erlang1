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

%TODO process kill
ringA(N,M) ->
  BuidStart = get_timestamp(),
  HomeProcess = self(),
  NextPID = case N of
     Num when Num=:=1 -> self()!{self(),buildComplete},HomeProcess;
     _ -> spawn(fun() -> processA(N-1,HomeProcess) end)
  end,
  receive
  {_Sender,buildComplete}->
    masterMessagePasser(NextPID,M,BuidStart)
  end
.
masterMessagePasser(_,0,StartTime)->
  io:format("Time Took For Build and Passing (Micros): ~p~n", [get_timestamp() - StartTime]);
masterMessagePasser(NextPID,M,StartTime) ->
  NextPID!{self(),message},
  receive
    {_Sender,message}->
      masterMessagePasser(NextPID,M-1,StartTime)
  end.


processA(1,HomeProcess)->
  HomeProcess!{self(),buildComplete},
  retransmitter(HomeProcess);

processA(NextProcessesNum,HomeProcess) ->
  NextPID = case NextProcessesNum of
    Num when Num=:=1 -> HomeProcess;
    _ -> spawn(fun() -> processA(NextProcessesNum-1,HomeProcess) end)
  end,
  retransmitter(NextPID).

retransmitter(NextProcess) ->
  receive
    {_Sender,Message}->
      NextProcess ! {self(),Message},
      retransmitter(NextProcess);
    _ ->
      retransmitter(NextProcess)
  end.

ringB(N,M)->
  BuidStart = get_timestamp(),
  HomeProcess = self(),
  NextPID = case N of
    Num when Num=:=1 -> HomeProcess;
    _ -> processCreatorB(N-1,HomeProcess)
  end,
  masterMessagePasser(NextPID,M,BuidStart)
.

processB(NextPID) ->
  retransmitter(NextPID).

processCreatorB(0,HomeProcess) ->HomeProcess;
processCreatorB(N,HomeProcess) ->
  spawn(fun() -> processB(processCreatorB(N-1,HomeProcess)) end).

%%%%%%

mesh(N,M,C) ->
  ProcessMap = createMesh(N*N,N,C,#{},M,get_timestamp()),
  updateProcessesWithMap(ProcessMap),
  maps:get(C, ProcessMap)!{self(),matrixCreated}
.

updateProcessesWithMap(ProcessMap) ->
  Fun = fun(K,V,AccIn) -> V!{self(),processMapUpdate,ProcessMap} end,
  maps:fold(Fun,0,ProcessMap)
.

createMesh(0,N,C,ProcessMap,M,StartTime) -> ProcessMap;
createMesh(C,N,C,ProcessMap,M,StartTime)-> %case master
  createMesh(C-1,N,C,ProcessMap#{C=>spawn(fun() -> meshMasterProcess(N,M,N,#{},#{},(N*N-1)*M,StartTime,0) end)},M,StartTime);
createMesh(NumLeft,N,C,ProcessMap,M,StartTime)->%case transmitter
  createMesh(NumLeft-1,N,C,ProcessMap#{NumLeft=>spawn(fun() -> meshTransmitterProcess(NumLeft,N,M,C,#{},#{}) end)},M,StartTime).

meshMasterProcess(_,_,_,_,MessageMap,ACKNum,StartTime,ACKNum) ->
  io:format("Time Took For Creating and Passing (Micros): ~p~n", [get_timestamp() - StartTime]);
meshMasterProcess(N,M,C,ProcessMap,MessageMap,ACKNum,StartTime,ACKReceived) ->
  receive
    {_Sender,processMapUpdate,Map} ->
      %io:format("MapUpdated: ~p~n", [Map]),
      meshMasterProcess(N,M,C,Map,MessageMap,ACKNum,StartTime,ACKReceived);
    {_Sender,matrixCreated}->
      meshMasterInitialSend(N,M,C,ProcessMap),
      meshMasterProcess(N,M,C,ProcessMap,MessageMap,ACKNum,StartTime,ACKReceived);
    {_DIR,{messageReceived,MessageNum,ProcessNum}}->
      %io:format("Master MessageReceived: ~p procc: ~p ~n", [MessageNum,ProcessNum]),
      NewMessageMap = MessageMap#{{MessageNum,ProcessNum}=>a},
      %io:format("Master MapSize: ~p ~n", [maps:size(NewMessageMap)]),
      meshMasterProcess(N,M,C,ProcessMap,NewMessageMap,ACKNum,StartTime,maps:size(NewMessageMap));
    _ -> %new message messages should not be handled
      meshMasterProcess(N,M,C,ProcessMap,MessageMap,ACKNum,StartTime,ACKReceived)
  end.

meshTransmitterProcess(MyNum,N,M,C,ProcessMap,MessageMap) ->
  receive
    {_Sender,processMapUpdate,Map} ->
      %io:format("MapUpdated: ~p~n", [Map]),
      meshTransmitterProcess(MyNum,N,M,C,Map,MessageMap);
    {DIR,{messageReceived,MessageNum,ProcessNum}}->
      case maps:is_key({messageReceived,MessageNum,ProcessNum},MessageMap) of
        false -> %if message hasnt already been received
          sendToDirsExcept(MyNum,N,ProcessMap,{messageReceived,MessageNum,ProcessNum},none),
          meshTransmitterProcess(MyNum,N,M,C,ProcessMap,MessageMap#{{messageReceived,MessageNum,ProcessNum}=>a});
        _ ->
          meshTransmitterProcess(MyNum,N,M,C,ProcessMap,MessageMap)
      end;
    {DIR,{newMessage,MessageNum}}->
      case maps:is_key({newMessage,MessageNum},MessageMap) of
        false -> %if message hasnt already been received
          sendToDirsExcept(MyNum,N,ProcessMap,{newMessage,MessageNum},none),
          sendToDirsExcept(MyNum,N,ProcessMap,{messageReceived,MessageNum,MyNum},none),
%%          sendUpwards(MyNum,N,ProcessMap,{messageReceived,MessageNum,MyNum}),
%%          sendDownwards(MyNum,N,ProcessMap,{messageReceived,MessageNum,MyNum}),
%%          sendRight(MyNum,N,ProcessMap,{messageReceived,MessageNum,MyNum}),
%%          sendLeft(MyNum,N,ProcessMap,{messageReceived,MessageNum,MyNum}),

          meshTransmitterProcess(MyNum,N,M,C,ProcessMap,MessageMap#{{newMessage,MessageNum}=>a});
        _ ->
          meshTransmitterProcess(MyNum,N,M,C,ProcessMap,MessageMap)
      end;
    _ -> %new message messages should not be handled
      meshTransmitterProcess(MyNum,N,M,C,ProcessMap,MessageMap)
end.

meshMasterInitialSend(N,0,C,ProcessMap) -> initialSendFinished;
meshMasterInitialSend(N,M,C,ProcessMap) ->
  sendUpwards(C,N,ProcessMap,{newMessage,M}),
  sendDownwards(C,N,ProcessMap,{newMessage,M}),
  sendRight(C,N,ProcessMap,{newMessage,M}),
  sendLeft(C,N,ProcessMap,{newMessage,M}),
  meshMasterInitialSend(N,M-1,C,ProcessMap)
.
sendToDirsExcept(MyNum,N,ProcessMap,Message,none) ->
  sendUpwards(MyNum,N,ProcessMap,Message),
  sendDownwards(MyNum,N,ProcessMap,Message),
  sendRight(MyNum,N,ProcessMap,Message),
  sendLeft(MyNum,N,ProcessMap,Message);
sendToDirsExcept(MyNum,N,ProcessMap,Message,up) ->
  sendDownwards(MyNum,N,ProcessMap,Message),
  sendRight(MyNum,N,ProcessMap,Message),
  sendLeft(MyNum,N,ProcessMap,Message);
sendToDirsExcept(MyNum,N,ProcessMap,Message,down) ->
  sendUpwards(MyNum,N,ProcessMap,Message),
  sendRight(MyNum,N,ProcessMap,Message),
  sendLeft(MyNum,N,ProcessMap,Message);
sendToDirsExcept(MyNum,N,ProcessMap,Message,left) ->
  sendDownwards(MyNum,N,ProcessMap,Message),
  sendRight(MyNum,N,ProcessMap,Message),
  sendUpwards(MyNum,N,ProcessMap,Message);
sendToDirsExcept(MyNum,N,ProcessMap,Message,right) ->
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
  {_Mega, _Sec, Micro} = os:timestamp(),
  Micro.