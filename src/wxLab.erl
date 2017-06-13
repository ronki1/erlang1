%% File for wxWidget Lab
-module(wxLab).
-export([start/1]).
-include_lib("wx/include/wx.hrl").
  -define(max_x,(1024)).
  -define(max_y,(768)).

  

  %% Creeates the window and menus etc.
start(NUM) ->
    Wx = wx:new(),
    Frame = wxFrame:new(Wx, -1, "Concurent and Distributed LAB", [{size, {?max_x, ?max_y}}]),
    Panel = wxPanel:new(Frame),
    OnPaint = fun(_Evt, _Obj) ->
	    Brush = wxBrush:new(),
	Paint = wxPaintDC:new(Panel),
	wxDC:setBrush(Paint, Brush),
	wxDC:drawLabel(Paint,"Press File-> Start to Begin .",{(?max_x) div 3,(?max_y) div 3,200,200}),

   end,
   wxFrame:connect(Panel, paint, [{callback, OnPaint}]),

	MenuBar = wxMenuBar:new(),
	wxFrame:setMenuBar (Frame, MenuBar),
	wxFrame:getMenuBar (Frame),
	FileMn = wxMenu:new(),
	wxMenuBar:append (MenuBar, FileMn, "&File"),
	Start=wxMenuItem:new ([{id,300},{text, "&Start"}]),wxMenu:append (FileMn, Start),
	LineD=wxMenuItem:new ([{id,600},{text, "&Draw Line"}]),wxMenu:append (FileMn, LineD),
	Circ=wxMenuItem:new ([{id,700},{text, "&Draw Circle"}]),wxMenu:append (FileMn, Circ),
	Quit = wxMenuItem:new ([{id,400},{text, "&Quit"}]),wxMenu:append (FileMn, Quit),
	HelpMn = wxMenu:new(),
	wxMenuBar:append (MenuBar, HelpMn, "&Help"),
	About = wxMenuItem:new ([{id,500},{text,"About"}]),
	wxMenu:append (HelpMn, About),
	wxFrame:connect (Frame, command_menu_selected),
    wxFrame:show(Frame),
       loop(Frame,Panel,Params). % pass the needed parameters here
       

%% Handles all the menu bar commands
    loop(Frame,Panel,Params) -> 
    receive 
    {_,X,_,_,_}-> 
	io:fwrite("~p ~n", [X]),
	case X of
	500 -> 
	400 -> 
	600 -> 
	700 ->
	300 -> 	
	_ -> 
	end.

%%draw function	
draw_line(X,Y,Dot2,Dot1)-> Paint = wxPaintDC:new(Panel),
	Brush = wxBrush:new(),
	wxBrush:setColour(Brush, ?wxBLUE),
	wxDC:setBrush(Paint,Brush),
	wxDC:drawLine(Paint,Dot2,Dot1), %draw line between two dots
	wxBrush:setColour(Brush, ?wxGREEN),
	wxDC:drawCircle(Paint ,{X,Y},3),  %draw circle center at {X,Y}
	wxBrush:destroy(Brush),
	wxPaintDC:destroy(Paint).
	