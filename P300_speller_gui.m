function varargout = P300_speller_gui(varargin)
% P300_SPELLER_GUI MATLAB code for P300_speller_gui.fig
%      P300_SPELLER_GUI, by itself, creates a new P300_SPELLER_GUI or raises the existing
%      singleton*..
%
%      H = P300_SPELLER_GUI returns the handle to a new P300_SPELLER_GUI or the handle to
%      the existing singleton*.
%
%      P300_SPELLER_GUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in P300_SPELLER_GUI.M with the given input arguments.
%
%      P300_SPELLER_GUI('Property','Value',...) creates a new P300_SPELLER_GUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before P300_speller_gui_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to P300_speller_gui_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help P300_speller_gui

% Last Modified by GUIDE v2.5 24-Feb-2016 15:00:24

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @P300_speller_gui_OpeningFcn, ...
                   'gui_OutputFcn',  @P300_speller_gui_OutputFcn, ...
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


% --- Executes just before P300_speller_gui is made visible.
function P300_speller_gui_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to P300_speller_gui (see VARARGIN)

% Choose default command line output for P300_speller_gui
handles.output = hObject;

% UIWAIT makes P300_speller_gui wait for user response (see UIRESUME)
% uiwait(handles.figure1);

handles.speller = p300_speller(handles);

% set position of all panels to top
handles.traininginstructpanel.Position = handles.menupanel.Position;
handles.trainingpanel.Position = handles.menupanel.Position;
handles.spellerpanel.Position = handles.menupanel.Position;
handles.settingspanel.Position = handles.menupanel.Position;

% Update handles structure
guidata(hObject, handles);




% --- Outputs from this function are returned to the command line.
function varargout = P300_speller_gui_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on button press in loadprofile.
function loadprofile_Callback(hObject, eventdata, handles)
% hObject    handle to loadprofile (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
uiopen('P300_Speller_Profiles\profile.mat');
handles.speller.classifier = classifier;
handles.trainingcompleted.String = sprintf('Training completed: %d chars',size(handles.speller.classifier.windows,1)/handles.speller.ROWS_AND_COLS);

% --- Executes on button press in saveprofile.
function saveprofile_Callback(hObject, eventdata, handles)
% hObject    handle to saveprofile (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
 classifier = handles.speller.classifier;
 uisave('classifier','P300_Speller_Profiles\profile.mat');

% --- Executes on button press in clearprofile.
function clearprofile_Callback(hObject, eventdata, handles)
% hObject    handle to clearprofile (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.speller.classifier = p300_classifier(handles.speller.eeg);
handles.trainingcompleted.String = 'Training completed: 0 chars';


% --- Executes on button press in settingsbutton.
function settingsbutton_Callback(hObject, eventdata, handles)
% hObject    handle to settingsbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.menupanel.Visible = 'off';
handles.settingspanel.Visible = 'on';

handles.dummyinput.Value = handles.speller.eeg.dummy_input;
handles.normalbrightness.String = num2str(handles.speller.grey_col(1),3);
handles.flashbrightness.String = num2str(handles.speller.flash_col(1),3);
handles.flashcharsize.String = num2str(handles.speller.big_char_size);
handles.normalcharsize.String = num2str(handles.speller.small_char_size);
handles.flashfreq.String = num2str(handles.speller.flash_freq,2);
handles.numreps.String = num2str(handles.speller.num_reps);
handles.numtrainingwords.String = num2str(handles.speller.num_training_words);

% --- Executes on button press in startspelling.
function startspelling_Callback(hObject, eventdata, handles)
% hObject    handle to startspelling (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if ~handles.speller.classifier.trained
    msgbox('You must train the classifier before beggining spelling');
else
    handles.menupanel.Visible = 'off';
    handles.spellerpanel.Visible = 'on';
    handles.speller.spell();
end

% --- Executes on button press in starttraining.
function starttraining_Callback(hObject, eventdata, handles)
% hObject    handle to starttraining (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.menupanel.Visible = 'off';
handles.traininginstructpanel.Visible = 'on';


% --- Executes on button press in starttraininginstruct.
function starttraininginstruct_Callback(hObject, eventdata, handles)
% hObject    handle to starttraininginstruct (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.traininginstructpanel.Visible = 'off';
handles.trainingpanel.Visible = 'on';
handles.speller.train();
handles.trainingpanel.Visible = 'off';
handles.menupanel.Visible = 'on';
handles.trainingcompleted.String = sprintf('Training completed: %d chars',size(handles.speller.classifier.windows,1)/handles.speller.ROWS_AND_COLS);


% --- Executes on button press in traininginstructcancel.
function traininginstructcancel_Callback(hObject, eventdata, handles)
% hObject    handle to traininginstructcancel (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.traininginstructpanel.Visible = 'off';
handles.menupanel.Visible = 'on';



% --- Executes on button press in trainingcancel.
function trainingcancel_Callback(hObject, eventdata, handles)
% hObject    handle to trainingcancel (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.speller.eeg.cancelled = true;
handles.speller.cancelled = true;
handles.trainingpanel.Visible = 'off';
handles.menupanel.Visible = 'on';


% --- Executes on button press in pushbutton14.
function pushbutton14_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton14 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in spellingcancel.
function spellingcancel_Callback(hObject, eventdata, handles)
% hObject    handle to spellingcancel (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.speller.cancelled = true;
handles.speller.eeg.cancelled = true;
handles.spellerpanel.Visible = 'off';
handles.menupanel.Visible = 'on';


function usernametext_Callback(hObject, eventdata, handles)
% hObject    handle to usernametext (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of usernametext as text
%        str2double(get(hObject,'String')) returns contents of usernametext as a double


% --- Executes during object creation, after setting all properties.
function usernametext_CreateFcn(hObject, eventdata, handles)
% hObject    handle to usernametext (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in settingscanel.
function settingscanel_Callback(hObject, eventdata, handles)
% hObject    handle to settingscanel (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.settingspanel.Visible = 'off';
handles.menupanel.Visible = 'on';


% --- Executes on button press in applysettingsbutton.
function applysettingsbutton_Callback(hObject, eventdata, handles)
% hObject    handle to applysettingsbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


try
    % check input values
    normalbrightness = str2double(handles.normalbrightness.String);
    assert(~isnan(normalbrightness) && normalbrightness >= 0 && normalbrightness <= 1,'MATLAB:badval','Invalid value for Normal brightness');
    flashbrightness = str2double(handles.flashbrightness.String);
    assert(~isnan(flashbrightness) && flashbrightness >= 0 && flashbrightness <= 1,'MATLAB:badval','Invalid value for Flash brightness');
    flashcharsize = str2double(handles.flashcharsize.String);
    assert(~isnan(flashcharsize) && rem(flashcharsize,1)==0 && flashcharsize>0,'MATLAB:badval','Invalid value for Flash character size');
    normalcharsize = str2double(handles.normalcharsize.String);
    assert(~isnan(normalcharsize) && rem(normalcharsize,1)==0 && normalcharsize>0,'MATLAB:badval','Invalid value for Normal character size');
    flashfreq = str2double(handles.flashfreq.String);
    assert(~isnan(flashfreq) && flashfreq>0,'MATLAB:badval','Invalid value for flash frequency');
    numreps = str2double(handles.numreps.String);
    assert(~isnan(numreps) && rem(numreps,1)==0 && numreps>0,'MATLAB:badval','Invalid value for Trials per row/col');
    numtrainingwords = str2double(handles.numtrainingwords.String);
    assert(~isnan(numtrainingwords) && rem(numtrainingwords,1)==0 && numtrainingwords>0,'MATLAB:badval','Invalid value for Training words');

    % apply values
    handles.speller.eeg.dummy_input = handles.dummyinput.Value;
    handles.speller.grey_col = [normalbrightness,normalbrightness,normalbrightness];
    handles.speller.flash_col = [flashbrightness,flashbrightness,flashbrightness];
    handles.speller.big_char_size = flashcharsize;
    handles.speller.small_char_size = normalcharsize;
    handles.speller.flash_freq = flashfreq;
    handles.speller.num_reps = numreps;
    handles.speller.num_training_words = numtrainingwords;
    
    % change panel
    handles.settingspanel.Visible = 'off';
    handles.menupanel.Visible = 'on';
    
catch ME
    if strcmp(ME.identifier,'MATLAB:badval')
        beep;
        disp(ME.message);
        msgbox(ME.message,'Error','error');
    else
        rethrow(ME);
    end
end



% --- Executes on button press in dummyinput.
function dummyinput_Callback(hObject, eventdata, handles)
% hObject    handle to dummyinput (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of dummyinput



function flashfreq_Callback(hObject, eventdata, handles)
% hObject    handle to flashfreq (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of flashfreq as text
%        str2double(get(hObject,'String')) returns contents of flashfreq as a double


% --- Executes during object creation, after setting all properties.
function flashfreq_CreateFcn(hObject, eventdata, handles)
% hObject    handle to flashfreq (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function numreps_Callback(hObject, eventdata, handles)
% hObject    handle to numreps (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of numreps as text
%        str2double(get(hObject,'String')) returns contents of numreps as a double


% --- Executes during object creation, after setting all properties.
function numreps_CreateFcn(hObject, eventdata, handles)
% hObject    handle to numreps (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function numtrainingwords_Callback(hObject, eventdata, handles)
% hObject    handle to numtrainingwords (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of numtrainingwords as text
%        str2double(get(hObject,'String')) returns contents of numtrainingwords as a double


% --- Executes during object creation, after setting all properties.
function numtrainingwords_CreateFcn(hObject, eventdata, handles)
% hObject    handle to numtrainingwords (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function flashcharsize_Callback(hObject, eventdata, handles)
% hObject    handle to flashcharsize (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of flashcharsize as text
%        str2double(get(hObject,'String')) returns contents of flashcharsize as a double


% --- Executes during object creation, after setting all properties.
function flashcharsize_CreateFcn(hObject, eventdata, handles)
% hObject    handle to flashcharsize (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function normalcharsize_Callback(hObject, eventdata, handles)
% hObject    handle to normalcharsize (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of normalcharsize as text
%        str2double(get(hObject,'String')) returns contents of normalcharsize as a double


% --- Executes during object creation, after setting all properties.
function normalcharsize_CreateFcn(hObject, eventdata, handles)
% hObject    handle to normalcharsize (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function flashbrightness_Callback(hObject, eventdata, handles)
% hObject    handle to flashbrightness (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of flashbrightness as text
%        str2double(get(hObject,'String')) returns contents of flashbrightness as a double


% --- Executes during object creation, after setting all properties.
function flashbrightness_CreateFcn(hObject, eventdata, handles)
% hObject    handle to flashbrightness (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function normalbrightness_Callback(hObject, eventdata, handles)
% hObject    handle to normalbrightness (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of normalbrightness as text
%        str2double(get(hObject,'String')) returns contents of normalbrightness as a double


% --- Executes during object creation, after setting all properties.
function normalbrightness_CreateFcn(hObject, eventdata, handles)
% hObject    handle to normalbrightness (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
