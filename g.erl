-module(g).

-export([start/0, list_to_number/1, calc_angle/1]).
-include_lib("wx/include/wx.hrl").

start() ->
    Wx = wx:new(),
    Frame = wxFrame:new(Wx, -1, "Draw Angle", [{size, {400, 400}}]),
    Panel = wxPanel:new(Frame),
    B101  = wxButton:new(Panel, 101, [{label, "&Degrees"}]),
    T1001 = wxTextCtrl:new(Panel, 1001,[{value, "0"}]), %set default value
    Sizer = wxBoxSizer:new(?wxHORIZONTAL),
    VSizer = wxBoxSizer:new(?wxVERTICAL),
 
    OnPaint = fun(_Evt, _Obj) ->
            io:format("OnPaint~n",[]),    
            Paint = wxPaintDC:new(Panel),
            Pen = wxPen:new(),
            wxPen:setColour(Pen, ?wxRED),
            wxDC:setPen(Paint, Pen), 
            wxDC:drawCircle(Paint, {200,200}, 50),
%%            wxDC:drawArc(Paint, {300,200} , {300,200} , {200,200}),
%%            wxDC:drawArc(Paint, {300,200} , {100,200} , {200,200}),
%%            wxDC:drawArc(Paint, {100,200} , {300,200} , {200,200}),

            wxDC:drawLine(Paint, {200, 200}, {300,200}), % 100 pixels long

        	wxPen:destroy(Pen),
            wxPaintDC:destroy(Paint)
	      end,

    wxSizer:prependSpacer(Sizer, 10),
    wxSizer:add(Sizer,T1001),
    wxSizer:addSpacer(Sizer, 5),
    wxSizer:add(Sizer,B101),

    wxSizer:prependSpacer(VSizer, 10),
    wxSizer:add(VSizer, Sizer),
    
    wxPanel:setSizer(Panel,VSizer),

    wxFrame:connect(Panel, paint, [{callback, OnPaint}]),
    wxFrame:connect(Panel, command_button_clicked),
    wxFrame:connect(Frame, close_window),

    wxFrame:center(Frame),
    wxFrame:show(Frame),
    loop({Frame,Panel,T1001}).
    
loop(State) ->
    {Frame,Panel,T1001}  = State,  
    io:format("--waiting in the loop--~n", []), 
    receive
        #wx{event=#wxClose{}} ->
            io:format("Closing window ~n",[]), 
            wxWindow:destroy(Frame),  
            ok; 

        A = #wx{id = ID, event=#wxCommand{type = command_button_clicked}} ->
            io:format("Button clicked:~p ~n",[ID]),
            io:format("wx event info: ~p ~n",[A]),

            T1001_val = wxTextCtrl:getValue(T1001),
            case list_to_number(T1001_val) of   
                badarg ->
                    io:format("Only numbers are allowed in textctrl~n",[]);
                Number ->     

                    OnPaint2 = fun(_Evt, _Obj) ->
                        io:format("OnPaint2~n",[]),
                        % redraw base line     
                        Paint = wxPaintDC:new(Panel),
                        Pen = wxPen:new(),
                        wxPen:setColour(Pen, ?wxRED),
                        wxDC:setPen(Paint, Pen),
                        %%wxDC:drawCircle(Paint, {200,200}, 100),
                        %%wxDC:drawArc(Paint, {300,200} , {100,200} , {200,200}),
                        %%wxDC:drawArc(Paint, {100,200} , {300,200} , {200,200}),
                        wxDC:drawLine(Paint, {200, 200}, {300,200}),

                        %same pen, change color    
                        wxPen:setColour(Pen, ?wxBLUE),
                        wxDC:setPen(Paint, Pen), 

                        {NewX, NewY} = calc_angle(Number),
                        wxDC:drawCircle(Paint, {NewX,NewY}, 50),
                        wxDC:drawLine(Paint, {200, 200}, {NewX, NewY}),
                        wxPen:destroy(Pen),
                        wxPaintDC:destroy(Paint)
                    end,

                    wxFrame:connect(Panel, paint, [{callback, OnPaint2}])
                    ,wxWindow:refreshRect(Frame,{200,200,1,1})
            end,        
            loop(State);
    
        Msg ->
            %everything else ends up here
            io:format("loop default triggered: Got ~n ~p ~n", [Msg]),
            loop(State)

    end.


%Degrees -> Radians: degrees * pi / 180
%Radians -> Degrees: radians * 180 / pi


%radians  6.2832 is approx 2 pi radians
calc_angle(Number) ->
    Radians = Number * math:pi() / 180,
    Cos = round(math:cos(Radians) * 100)  + 200,  %x
    Sin = -round(math:sin(Radians) * 100) + 200,  %y
    io:format("X ~p Y ~p~n", [Cos, Sin]),
    {Cos, Sin}.     


%list_to_number/1
%  returns an int or a float or badarg
list_to_number(Number) ->
  try list_to_integer( Number) of
    Val_integer -> Val_integer
  catch  
    error:_Why -> try list_to_float(Number) of
                    Val_float -> Val_float
                  catch 
                    error: Reason -> Reason
                  end   
  end.  