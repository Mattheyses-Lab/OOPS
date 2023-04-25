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

    % restrict log window to only hold the last ~200 messages
    
    PODSData = guidata(source);
    if strcmp(operation,'append')
        if length(PODSData.Handles.LogWindow.Value) > 199
            PODSData.Handles.LogWindow.Value = {PODSData.Handles.LogWindow.Value{end-199:end},msg};
        else
            if strcmp(PODSData.Handles.LogWindow.Value{1},'')
                PODSData.Handles.LogWindow.Value{end} = msg;
            else
                PODSData.Handles.LogWindow.Value{end+1} = msg;
            end
        end
    else
        PODSData.Handles.LogWindow.Value{end} = msg;
    end    
    
    scroll(PODSData.Handles.LogWindow,'bottom');
    
    drawnow
    
end