%%%-------------------------------------------------------------------
%%% @author ron
%%% @copyright (C) 2017, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 03. Apr 2017 08:45
%%%-------------------------------------------------------------------
-module(grade).
-author("ron").

%% API
-export([gradeCalc/2]).

gradeCalc(Grade,Factor)-> gradeCalcHelper(Grade,Factor,Grade<56).

gradeCalcHelper(Grade,Factor,true)-> Grade;
gradeCalcHelper(Grade,Factor,false)-> Grade*Factor.