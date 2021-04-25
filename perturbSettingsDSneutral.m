function pertSet = perturbSettingsDSneutral;

	pertFactorF1 = 0;
    pertFactorF2 = [220 370 520 970];

    for i = 1:length(pertFactorF2)
    	if i == 4
    		pertSet.(['pertSettings_' mat2str(pertFactorF2(i)) '_d']) = makepertstring(+pertFactorF1, -pertFactorF2(i));
        	pertSet.(['pertSettings_' mat2str(pertFactorF2(i)) '_up']) = makepertstring(+pertFactorF1, +pertFactorF2(i-1));
    	else
        	pertSet.(['pertSettings_' mat2str(pertFactorF2(i)) '_d']) = makepertstring(+pertFactorF1, -pertFactorF2(i));
        	pertSet.(['pertSettings_' mat2str(pertFactorF2(i)) '_up']) = makepertstring(+pertFactorF1, +pertFactorF2(i));
        end
    end
end