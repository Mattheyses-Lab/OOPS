function boundariesTest(bw)

tic

boundariesMATLAB = bwboundaries(bw,8,'TraceStyle','pixeledge');

timeElapsed = toc;

disp(['MATLAB: ',num2str(timeElapsed),' s']);



tic

boundariesME = getPerfectBinaryBoundaries(bw,'conn',4);

timeElapsed = toc;

disp(['ME: ',num2str(timeElapsed),' s']);


end