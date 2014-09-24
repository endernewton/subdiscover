% GNU licence:
% Copyright (C) 2012  Itay Blumenthal
% 
%     This program is free software; you can redistribute it and/or modify
%     it under the terms of the GNU General Public License as published by
%     the Free Software Foundation; either version 2 of the License, or
%     (at your option) any later version.
% 
%     This program is distributed in the hope that it will be useful,
%     but WITHOUT ANY WARRANTY; without even the implied warranty of
%     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%     GNU General Public License for more details.
% 
%     You should have received a copy of the GNU General Public License
%     along with this program; if not, write to the Free Software
%     Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USAfunction finalLabel = GCAlgo( im, fixedBG,  K, G, maxIterations, Beta, diffThreshold, myHandle )

function varargout = GC_GUI(varargin)

gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
    'gui_Singleton',  gui_Singleton, ...
    'gui_OpeningFcn', @GC_GUI_OpeningFcn, ...
    'gui_OutputFcn',  @GC_GUI_OutputFcn, ...
    'gui_LayoutFcn',  [] , ...
    'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT

% --- Executes just before GC_GUI is made visible.
function GC_GUI_OpeningFcn(hObject, eventdata, handles, varargin)
global CurrRes;
CurrRes = [];
handles.output = hObject;
handles.K_max = 12;
handles.K_min = 2;

handles.Beta_max = 5;
handles.Beta_min = 0.01;

handles.K_value = 6;
handles.Beta_value = 0.3;
set(handles.K_text,'String',num2str(handles.K_value ));
set(handles.Beta_text,'String',num2str(handles.Beta_value ));

imshow([],'Parent',handles.DrawOrigIm);
imshow([],'Parent',handles.DrawPolygon);
imshow([],'Parent',handles.CurrResult);
imshow([],'Parent',handles.PrevResult);

% Update handles structure
guidata(hObject, handles);

% --- Outputs from this function are returned to the command line.
function varargout = GC_GUI_OutputFcn(hObject, eventdata, handles)

varargout{1} = handles.output;

% --- Executes on button press in OpenImage.
function OpenImage_Callback(hObject, eventdata, handles)
FilterSpec = ['*'];
[FileName,PathName,FilterIndex] = uigetfile(FilterSpec);
fullFileName = strcat(PathName, FileName);
global im;
im = imread(fullFileName);
imshow(im,'Parent',handles.DrawOrigIm);
% hObject    handle to OpenImage (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in MarkPolygon.
function MarkPolygon_Callback(hObject, eventdata, handles)
global fixedBG;
global im;
set(handles.Processbar,'Visible','off');
set(handles.instruction_1,'Visible','on');
set(handles.instruction_2,'Visible','on');
set(handles.instruction_3,'Visible','on');

disp('sfgasdfgasdfg');
imshow(im,'Parent',handles.DrawPolygon);

fixedBG = ~roipoly(im);
imshow(fixedBG, 'Parent', handles.DrawPolygon);

%%% show red bounds:
imBounds = im;
bounds = double(abs(edge(fixedBG)));
se = strel('square',3);
bounds = 1 - imdilate(bounds,se);
imBounds(:,:,2) = imBounds(:,:,2).*uint8(bounds);
imBounds(:,:,3) = imBounds(:,:,3).*uint8(bounds);
imshow(imBounds, 'Parent', handles.DrawPolygon);


set(handles.instruction_1,'Visible','off');
set(handles.instruction_2,'Visible','off');
set(handles.instruction_3,'Visible','off');

% --- Executes on button press in RunGC.
function RunGC_Callback(hObject, eventdata, handles)

set(handles.Processbar,'Visible','on');
global fixedBG;
global im;
global CurrRes;
global PrevRes;
PrevRes = CurrRes;
imd = double(im);
Beta = handles.Beta_value;
k = handles.K_value;
G = 50;
maxIter = 10;
diffThreshold = 0.001;
L = GCAlgo(imd, fixedBG,k,G,maxIter, Beta, diffThreshold, handles.Processbar);
L = double(1 - L);

CurrRes = imd.*repmat(L , [1 1 3]);

imshow(uint8(CurrRes), 'Parent', handles.CurrResult);
imshow(uint8(PrevRes), 'Parent', handles.PrevResult);

set(handles.Processbar,'String','Done');


% --- Executes on button press in LoadPolygon.
function LoadPolygon_Callback(hObject, eventdata, handles)
set(handles.Processbar,'Visible','off');
FilterSpec = ['*'];
[FileName,PathName,FilterIndex] = uigetfile(FilterSpec);
fullFileName = strcat(PathName, FileName);

global fixedBG;

fixedBG = logical(imread(fullFileName) < 128);
imshow(fixedBG, 'Parent', handles.DrawPolygon);

%%% show red bounds:
global im;
imBounds = im;
bounds = double(abs(edge(fixedBG)));
se = strel('square',3);
bounds = 1 - imdilate(bounds,se);
imBounds(:,:,2) = imBounds(:,:,2).*uint8(bounds);
imBounds(:,:,3) = imBounds(:,:,3).*uint8(bounds);
imshow(imBounds, 'Parent', handles.DrawPolygon);


function K_text_Callback(hObject, eventdata, handles)
if  (str2double(get(hObject,'String')) < handles.K_min)
    handles.K_value = handles.K_min;
elseif ( str2double(get(hObject,'String')) > handles.K_max )
    handles.K_value = handles.K_max;
else
    handles.K_value = str2double(get(hObject,'String'));
end
set(handles.K_text,'String',num2str(handles.K_value ));
guidata(hObject, handles);
% Hints: get(hObject,'String') returns contents of K_text as text
%        str2double(get(hObject,'String')) returns contents of K_text as a double


% --- Executes during object creation, after setting all properties.
function K_text_CreateFcn(hObject, eventdata, handles)
% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function Beta_text_Callback(hObject, eventdata, handles)
if  (str2double(get(hObject,'String')) < handles.Beta_min)
    handles.Beta_value = handles.Beta_min;
elseif ( str2double(get(hObject,'String')) > handles.Beta_max )
    handles.Beta_value = handles.Beta_max;
else
    handles.Beta_value = str2double(get(hObject,'String'));
end
set(handles.Beta_text,'String',num2str(handles.Beta_value ));
guidata(hObject, handles);
% Hints: get(hObject,'String') returns contents of Beta_text as text
%        str2double(get(hObject,'String')) returns contents of Beta_text as a double


% --- Executes during object creation, after setting all properties.
function Beta_text_CreateFcn(hObject, eventdata, handles)
% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function K_plus_Callback(hObject, eventdata, handles)
if ( handles.K_value < handles.K_max )
    handles.K_value = handles.K_value + 1;
    set(handles.K_text,'String',num2str(handles.K_value ));
    guidata(hObject, handles);
end

function K_minus_Callback(hObject, eventdata, handles)
if ( handles.K_value > handles.K_min )
    handles.K_value = handles.K_value - 1;
    set(handles.K_text,'String',num2str(handles.K_value ));
    guidata(hObject, handles);
end
function Beta_minus_Callback(hObject, eventdata, handles)
if ( handles.Beta_value > 0.1 + 0.000001)
    handles.Beta_value = handles.Beta_value - 0.1;
    set(handles.Beta_text,'String',num2str(handles.Beta_value ));
    guidata(hObject, handles);
elseif ( handles.Beta_value > handles.Beta_min + 0.000001)
    handles.Beta_value = handles.Beta_value - 0.01;
    set(handles.Beta_text,'String',num2str(handles.Beta_value ));
    guidata(hObject, handles);
end

function Beta_plus_Callback(hObject, eventdata, handles)
if ( handles.Beta_value < handles.Beta_max)
    if ( handles.Beta_value >= 0.1 - 1e-5)
        handles.Beta_value = handles.Beta_value + 0.1;
        set(handles.Beta_text,'String',num2str(handles.Beta_value ));
        guidata(hObject, handles);
    elseif ( handles.Beta_value >= handles.Beta_min-0.0001)
        handles.Beta_value = handles.Beta_value + 0.01;
        set(handles.Beta_text,'String',num2str(handles.Beta_value ));
        guidata(hObject, handles);
    end
end



function instruction_1_Callback(hObject, eventdata, handles)
% Hints: get(hObject,'String') returns contents of instruction_1 as text
%        str2double(get(hObject,'String')) returns contents of instruction_1 as a double


% --- Executes during object creation, after setting all properties.
function instruction_1_CreateFcn(hObject, eventdata, handles)
% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function instruction_3_Callback(hObject, eventdata, handles)

% --- Executes during object creation, after setting all properties.
function instruction_3_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function instruction_2_Callback(hObject, eventdata, handles)

% --- Executes during object creation, after setting all properties.
function instruction_2_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function Processbar_Callback(hObject, eventdata, handles)

% --- Executes during object creation, after setting all properties.
function Processbar_CreateFcn(hObject, eventdata, handles)

if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
