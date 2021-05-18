%% UpdateLog.m
% Author: Will Dean
% University of Alabama at Birmingham
% Lab of Dr. Alexa Mattheyses  
%%
function [] = UpdateLog3(source,msg,operation)

% updates the log window in PODS_GUI
% Takes 3 inputs, data, msg, and operation
% data is the PODS data structure holding all experimental information and
% figure objects, msg is the message to print to the log window, operation
% is the type of operation to perform, can be 'append' to add text onto
% existing text, or can remove and replace the most recent line of text if
% operation is set to 'replace'
% UpdateLog(data,msg,'append') gets the current text from log window and 
% appends msg to the end of it, before reprinting the new message in the 
% window


    PODSData = guidata(source);

    hLogWindow = PODSData.Handles.LogWindow;
    
    old_string = hLogWindow.Value
    
    % number of lines in log text
    sz = length(old_string);
    
    % variable to hold new value
    new_string = old_string;
    
    
    if strcmp(operation,'append')
        new_string{sz+1} = msg;
    else
        new_string{sz} = msg;
    end
    
    hLogWindow.Value = new_string;
    drawnow
    scroll(hLogWindow,'bottom')
    
    % get a handle to the underlying java object so that we can set the
    % caret position to bottom upon adding a new line of text
    

%     JHLogWindow = findjobj(hLogWindow);
%     JLogWindow = JhLogWindow.getComponent(0).getComponent(0);
%     JLogWindow.setCaretPosition(JLogWindow.getDocument.getLength);
        
    guidata(source,PODSData);

    
%     
%     data = guidata(source)
%     data.JLogWindow
    
    
end