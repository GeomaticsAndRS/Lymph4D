function varargout = viewer(varargin)
% VIEWER MATLAB code for viewer.fig
%      VIEWER, by itself, creates a new VIEWER or raises the existing
%      singleton*.
%
%      H = VIEWER returns the handle to a new VIEWER or the handle to
%      the existing singleton*.
%
%      VIEWER('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in VIEWER.M with the given input arguments.
%
%      VIEWER('Property','Value',...) creates a new VIEWER or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before viewer_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to viewer_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help viewer

% Last Modified by GUIDE v2.5 08-Feb-2017 18:49:55

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @viewer_OpeningFcn, ...
                   'gui_OutputFcn',  @viewer_OutputFcn, ...
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


% --- Executes just before viewer is made visible.
function viewer_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to viewer (see VARARGIN)

% Choose default command line output for viewer
handles.output = hObject;

% Initialize some "globals"
handles.lastExpFile = 'lastExp.mat';
handles.onImage = false;

% If experiment was passed use it as data
if 

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes viewer wait for user response (see UIRESUME)
% uiwait(handles.mainGui);


% --- Outputs from this function are returned to the command line.
function varargout = viewer_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Called when the window is closed
function viewer_ClosingFcn(hObject, eventdata, handles)
% hObject    handle to edit1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
delete(hObject);


% --- Executes on button press in selectExpBtn.
function selectExpBtn_Callback(hObject, eventdata, handles)
% hObject    handle to selectExpBtn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles = guidata(hObject);

% Let user select the experiment (directory)
path = uigetdir();

% Store path and files for fast access
[storePath, ~, ~] = fileparts(mfilename('fullpath'));
save(fullfile(storePath, handles.lastExpFile), 'path');

% Open and read the stack
handles = openExperiment(handles, path);

guidata(hObject, handles);


% --- Open and read the stack files
function handles = openExperiment(handles, path)

if exist(path, 'dir') == 0
    msgbox(strcat({'The experiment:' path 'is no longer available!'}));
    return
end

list = dir(path);

% Remove directories
list([list.isdir]) = [];

% Sort based on file name (filed 1)
flds = fieldnames(list);
tmp = struct2cell(list);
sz = size(tmp);
tmp = reshape(tmp, sz(1), [])';
tmp = sortrows(tmp, 1);
tmp = reshape(tmp', sz);
list = cell2struct(tmp, flds, 1);

% Extract the stack and slice number from each file and store in structure
rex = '^(.*?\.)(\d{4})\.(\d{4})\.(.*)$';
stackMin = inf;
stackMax = -inf;
sliceMin = inf;
sliceMax = -inf;
oldStack = inf;
stackNum = 0;
ex = struct();
for i = 1:length(list)
    tk = regexp(list(i).name, rex, 'tokens');
    if ~isempty(tk)
        stack = str2double(tk{1, 1}{1, 2});
        if stack < stackMin
            stackMin = stack;
        end
        if stack > stackMax
            stackMax = stack;
        end
        slice = str2double(tk{1, 1}{1, 3});
        if slice < sliceMin
            sliceMin = slice;
        end
        if slice > sliceMax
            sliceMax = slice;
        end
        if stack ~= oldStack
            stackNum = stackNum + 1;
            ex(stackNum).files = list(i);
            ex(stackNum).stack = stack;
            oldStack = stack;
        else
            ex(stackNum).files = [ex(stackNum).files list(i)];
            ex(stackNum).slices = slice;
        end
    end
end

% Drop the stacks with less than max number of slices?  
ex([ex.slices] < sliceMax) = [];
stackNum = length(ex);
handles.stackNum = stackNum;
handles.stackList = [ex.stack];
handles.sliceNum = sliceMax;

% Read the first image and use it as template to preallocate the stack
stackIdx = 1;
sliceIdx = 1;
fil = char(fullfile(path, ex(stackIdx).files(sliceIdx).name));
img1 = dicomread(fil);
img = zeros([size(img1), stackNum, sliceMax]);
img(:, :, stackIdx, sliceIdx) = img1;

% Load and store the stack
for st = 1 : stackNum
    for sl = 1 : sliceMax
        fil = char(fullfile(path, ex(st).files(sl).name));
        if exist(fil, 'file') == 0
            msgbox(strcat({'The file:' fil 'is no longer available!'}));
            return
        end
        img(:, :, st, sl) = dicomread(fil);
    end
end

% Store original stack
handles.stackOrig = img;

% Evaluate stack range
imgMin = min(img(:));
imgMax = max(img(:));
clims = [imgMin, imgMax];
handles.stackCLims = clims;

% Normalize stack to [0, 1]
% img = (img - imgMin) / (imgMax - imgMin);
handles.stackImg = img;

% Display image
axes(handles.mainAx);
handles.img = imagesc(img1, clims);
handles.stackIdx = stackIdx;
handles.sliceIdx = sliceIdx;

% Zero the sliders
set(handles.stackSlider, 'Value', 0);
set(handles.sliceSlider, 'Value', 0);

% Update display
handles = updateGui(handles);


% --- Executes on slider movement.
function sliceSlider_Callback(hObject, eventdata, handles)
% hObject    handle to sliceSlider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider
handles = guidata(hObject);

% Update image when user use the slider
try
    dx = 1.0 / (handles.sliceNum - 1);
    idx = 1 + floor(get(hObject, 'Value') / dx);
    if idx ~= handles.sliceIdx
        handles.sliceIdx = idx;
        set(handles.img, 'CData', handles.stackImg(:, :, handles.stackIdx, idx));    

        % Update array indexing
        handles = updateIdx(handles);

        % Update display
        handles = updateGui(handles);

        guidata(hObject, handles);
    end
catch ME
end

% --- Executes during object creation, after setting all properties.
function sliceSlider_CreateFcn(hObject, eventdata, handles)
% hObject    handle to sliceSlider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end

handles = guidata(hObject);

% Create listener for real time update with slider
handles.sliceSliderListener = addlistener(hObject, ...
                                          'ContinuousValueChange', ...
                                          @(hObject, eventdata) sliceSlider_Callback(hObject, eventdata));

guidata(hObject, handles);


% --- Executes on slider movement.
function stackSlider_Callback(hObject, ~, handles)
% hObject    handle to stackSlider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider
handles = guidata(hObject);

% Update image when user use the slider
try
    dx = 1.0 / (handles.stackNum - 1);
    idx = 1 + floor(get(hObject, 'Value') / dx);
    if idx ~= handles.stackIdx
        handles.stackIdx = idx;
        set(handles.img, 'CData', handles.stackImg(:, :, idx, handles.sliceIdx));    

        % Update array indexing
        handles = updateIdx(handles);
        
        % Update display
        handles = updateGui(handles);

        guidata(hObject, handles);
    end
catch ME
end

% --- Executes during object creation, after setting all properties.
function stackSlider_CreateFcn(hObject, eventdata, ~)
% hObject    handle to stackSlider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end

handles = guidata(hObject);

% Create listener for real time update with slider
handles.stackSliderListener = addlistener(hObject, ...
                                          'ContinuousValueChange', ...
                                          @(hObject, eventdata) stackSlider_Callback(hObject, eventdata));

guidata(hObject, handles);


% --- Executes on button press in exportOrig2Ws.
function exportOrig2Ws_Callback(hObject, eventdata, handles)
% hObject    handle to exportOrig2Ws (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles = guidata(hObject);

assignin('base', 'stackOrig', handles.stackOrig);

guidata(hObject, handles);


% --- Executes on button press in exportCurrent2Ws.
function exportCurrent2Ws_Callback(hObject, eventdata, handles)
% hObject    handle to exportCurrent2Ws (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles = guidata(hObject);

assignin('base', 'stackCurr', handles.stackImg);

guidata(hObject, handles);


% --- Executes on button press in runSlic.
function runSlic_Callback(hObject, eventdata, handles)
% hObject    handle to runSlic (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles = guidata(hObject);

img = handles.stackImg(:, :, handles.stackIdx, handles.sliceIdx);
[L, ~] = superpixels(img, 100, 'Compactness', 5);
BW = boundarymask(L, 4);
img(BW) = handles.stackCLims(2);
set(handles.img, 'CData', img);    

guidata(hObject, handles);


% --- Executes on button press in loadLatest.
function loadLatest_Callback(hObject, eventdata, handles)
% hObject    handle to loadLatest (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles = guidata(hObject);

[storePath, ~, ~] = fileparts(mfilename('fullpath'));
load(fullfile(storePath, handles.lastExpFile), 'path');

handles = openExperiment(handles, path);

guidata(hObject, handles);


% --- Executes on button press in clear.
function clear_Callback(hObject, eventdata, handles)
% hObject    handle to clear (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles = guidata(hObject);

set(handles.img, 'CData', handles.stackImg(:, :, handles.stackIdx, handles.sliceIdx));    

guidata(hObject, handles);


% --- Executes on mouse motion over figure - except title and menu.
function mainGui_WindowButtonMotionFcn(hObject, eventdata, handles)
% hObject    handle to mainGui (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles = guidata(hObject);

% Get location of mouse respect to application window
pos = get(hObject, 'currentPoint');  % (0,0) is bottom-left
pX = pos(1);
pY = pos(2);

% Get information about location and size of axes
maLoc = get(handles.mainAx, 'Position');
maL = maLoc(1);
maB = maLoc(2);
maW = maLoc(3);
maH = maLoc(4);

handles.onImage = false;

% Check if within image limits
if pX >= maL && pY >= maB
    maX = pX - maL;
    maY = pY - maB;
    if maX <= maW && maY <= maH
        handles.onImage = true;
        cPos = get(handles.mainAx, 'CurrentPoint');
        handles.posIdx = round(cPos(1, 1:2));
        handles = updateIdx(handles);  % Update array indexing
        handles = updateGui(handles);  % Update display
    end
end

guidata(hObject, handles);


% --- Executes on mouse press over figure background, over a disabled or
% --- inactive control, or over an axes background.
function mainGui_WindowButtonDownFcn(hObject, eventdata, handles)
% hObject    handle to mainGui (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles = guidata(hObject);

type = get(hObject,'SelectionType');
switch type
    case 'normal' % Left Single-Click
        if handles.onImage
            figure(1); 
            hold all;
            plot(squeeze(handles.stackOrig(handles.posIdx(2), handles.posIdx(1), :, handles.sliceIdx)));
        end
    case 'open' % Left Double-Click

end

guidata(hObject, handles);


% --- Update array indexing
function handles = updateIdx(handles)
try
    pos = [handles.posIdx(2), ...
           handles.posIdx(1), ...
           handles.stackIdx, ...
           handles.sliceIdx];
    handles.arrayIdx = num2cell(pos);
catch ME
end


% --- Update GUI
function handles = updateGui(handles)
handles = updateTxtSliceIdx(handles);
handles = updateTxtStackIdx(handles);
handles = updateTxtPosIdx(handles);


% --- Update index indicator
function handles = updateTxtSliceIdx(handles)
try
    txt = strcat('sl:', ...
                 num2str(handles.sliceIdx, '%03u'), ...
                 '/', ...
                 num2str(handles.sliceNum, '%03u'));

    set(handles.txtSliceIdx, 'String', txt);
catch ME
end


% --- Update time indicator
function handles = updateTxtStackIdx(handles)
try
    txt = strcat('st:', ...
                 num2str(handles.stackIdx, '%03u'), ...
                 '/', ...
                 num2str(handles.stackNum, '%03u'));

    set(handles.txtStackIdx, 'String', txt);
catch ME
end


% --- Update position indicator
function handles = updateTxtPosIdx(handles)
try
    txt = strcat('(', ...
                 num2str(handles.posIdx(1), '%03u'), ...
                 ',', ...
                 num2str(handles.posIdx(2), '%03u'), ...
                 ',', ...
                 num2str(handles.stackIdx, '%03u'), ...
                 ',', ...
                 num2str(handles.sliceIdx, '%03u'), ...
                 ')-', ...
                 num2str(handles.stackOrig(handles.arrayIdx{:}), '%04u'));
             
     set(handles.txtPosIdx, 'String', txt);
catch ME
end
