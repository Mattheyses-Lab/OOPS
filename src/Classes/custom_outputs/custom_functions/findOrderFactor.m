function OrderFactor = findOrderFactor(FPMStack)

FPMStackNorm = FPMStack./max(FPMStack,[],3);


a = FPMStackNorm(:,:,1) - FPMStackNorm(:,:,3);
b = FPMStackNorm(:,:,2) - FPMStackNorm(:,:,4);

OrderFactor = hypot(a,b);

end