%%%-------------------------------------------------------------------
%%% @author ron
%%% @copyright (C) 2017, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 15. May 2017 08:33
%%%-------------------------------------------------------------------
-module(ex6_204130538).
-author("ron").

%% API
-export([songList/1]).
-export([songGen/3]).

songList(Songs)->
  G = digraph:new(),%create new gragh
  buildGraph(G,Songs),%build graph
  io:fwrite(lists:flatten(io_lib:format("Number of Edges: ~p \n", [length(digraph:edges(G))]))),%print edges
  G%returnG
.

buildGraph(G,[]) ->%case finished going through list
  G;
buildGraph(G,[H|T]) ->
  HeadConnector = digraph:add_vertex(G, {integer_to_list(hd(H)),connector}),%create vertex to connect to the song
  TailConnector = digraph:add_vertex(G, {integer_to_list(lists:last(H)),connector}),%create vertex to be connected from the song
  SongVertex = digraph:add_vertex(G, {H, song}),%create song vertex
  digraph:add_edge(G,HeadConnector,SongVertex),%add edge to song from letter
  digraph:add_edge(G,SongVertex,TailConnector),%add edge from song
  buildGraph(G,T)%recurrsive call
.

songGen(_G,Start,Start) -> %return shortest path in graph
  [Start];
songGen(G,Start,End) -> %return shortest path in graph
  Path = digraph:get_short_path(G, {Start, song}, {End,song}),
  case Path of
    false -> notFound;
    _ -> lists:reverse(filterPath([],Path))
  end
.
filterPath(NewList,[])->%finished going through list
  NewList;
filterPath(NewList,[{H,song}|T]) ->%add song vertices
  filterPath([H|NewList],T);
filterPath(NewList,[_|T]) ->%remove letter vertices
  filterPath(NewList,T)
.