function pertSet = perturbSettingsLS(means, bias);

	% get field names
	fields = fieldnames(means);
	
	dyF2 = nanmean(fields{});
	guF2 = fields{};

	% compute mean distance between /y/ and /u/
	distan = dyF2-guF2;
	near = distan/100*30;
	far = distan/100*70;

	pertFactorF1 = 0;
    pertFactorF2near = near;
    pertFactorF2far = far;

    % phases
    phases = {'2_training', '3_test', '4_training', '5_test'};

    if bias == 'y'
    	for i = 1:2:length(phases)
        	pertSet.(['pertSettings_' mat2str(phases(i)) '_d']) = makepertstring(+pertFactorF1, -pertFactorF2near);
        	pertSet.(['pertSettings_' mat2str(phases(i)) '_up']) = makepertstring(+pertFactorF1, +pertFactorF2far);
    	end
    else
    	for i = 1:2:length(phases)
        	pertSet.(['pertSettings_' mat2str(phases(i)) '_d']) = makepertstring(+pertFactorF1, -pertFactorF2far);
        	pertSet.(['pertSettings_' mat2str(phases(i)) '_up']) = makepertstring(+pertFactorF1, +pertFactorF2near);
    	end
    end
end