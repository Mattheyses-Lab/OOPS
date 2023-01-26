function minimizeMLDesktop()
    % minimize the MATLAB desktop window
    desktop = com.mathworks.mde.desk.MLDesktop.getInstance();
    mf = desktop.getMainFrame;
    mf.setMinimized(true);
end