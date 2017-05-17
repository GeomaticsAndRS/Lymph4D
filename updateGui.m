% Copyright 2017 Andrea Vaccari (av9g@virginia.edu)

% --- Update GUI
function handles = updateGui(handles)
handles = updateTxtSliceIdx(handles);
handles = updateTxtStackIdx(handles);
handles = updateTxtPosIdx(handles);
handles = updateTxtExpName(handles);
handles = updateTxtTemplExpName(handles);


% --- Update index indicator
function handles = updateTxtSliceIdx(handles)
try
    txt = strcat('sl:', ...
                 num2str(handles.sliceIdx, '%03u'), ...
                 '/', ...
                 num2str(handles.sliceNum, '%03u'));
catch ME
    txt = 'sl:000/000';
end
set(handles.txtSliceIdx, 'String', txt);


% --- Update time indicator
function handles = updateTxtStackIdx(handles)
try
    txt = strcat('st:', ...
                 num2str(handles.stackIdx, '%03u'), ...
                 '/', ...
                 num2str(handles.stackNum, '%03u'));
catch ME
    txt = 'st:000/000';
end
set(handles.txtStackIdx, 'String', txt);


% --- Update experiment name
function handles = updateTxtExpName(handles)
try
    txt = strcat('Experiment:', ...
                 handles.expInfo.expName);
catch ME
    txt = 'Experiment:';
end
set(handles.txtExpName, 'String', txt);


% --- Update template experiment name
function handles = updateTxtTemplExpName(handles)
try
    txt = strcat('Experiment:', ...
                 handles.templExpName);
catch ME
    txt = 'Experiment:';
end
set(handles.txtTemplExpName, 'String', txt);


% --- Update position indicator
function handles = updateTxtPosIdx(handles)
try
    txt = strcat('(', ...
                 num2str(handles.posIdx(1), '%03u'), ...
                 ',', ...
                 num2str(handles.posIdx(2), '%03u'), ...
                 ',', ...
                 num2str(handles.sliceIdx, '%03u'), ...
                 ',', ...
                 num2str(handles.stackIdx, '%03u'), ...
                 ')-(', ...
                 num2str(min(handles.stackOrig(handles.arrayIdx{1:3}, :)), '%04u'), ...
                 '<', ...
                 num2str(handles.stackOrig(handles.arrayIdx{:}), '%04u'), ...
                 '<', ...
                 num2str(max(handles.stackOrig(handles.arrayIdx{1:3}, :)), '%04u'), ...
                 ')');
catch ME
    txt = '(000,000,000,000)-(0000<0000<0000)';
end
set(handles.txtPosIdx, 'String', txt);