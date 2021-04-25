
% make base stim file and randomized stim file for the baseline phase
	if strcmp(phaseString, 'baseline')

		if ~exist('basestudy', 'var')
			basestudy = input('Which study? (double sound = ds, vowel shift = vs, new sound = ns): ','s');
		end
		
		if strcmp(basestudy, 'ns')
			% text for the two configuration sound learning
			baselineText{1} = '1';
			baselineText{2} = 'Bitte artikuliere und "ziehe" die Vokale solange der Rahmen grün bleibt.';
			baselineText{3} = 'Aufgabenbeschreibung'; 
			baselineText{4} = 'ü';
			baselineText{5} = ['ue_1_0000_01_REP#fb 1#pertAmp 0#pertPhi pi*0#fn1 ' int2str(formants.ueF1) '#fn2 ' int2str(formants.ueF2) '%no perturbation'];
			baselineText{6} = 'u';
			baselineText{7} = ['u_1_0000_02_REP#fb 1#pertAmp 0#pertPhi pi*0#fn1 ' int2str(formants.uF1) '#fn2 ' int2str(formants.uF2) '%no perturbation'];
			% filler conditions at the end
			baselineText{8} = 'a';
			baselineText{9} = ['a_1_0000_03_REP#fb 1#pertAmp 0#pertPhi pi*0#fn1 ' int2str(formants.aF1) '#fn2 ' int2str(formants.aF2) '%no perturbation']; 
			baselineText{10} = 'ä';
			baselineText{11} = ['ae_1_0000_04_REP#fb 1#pertAmp 0#pertPhi pi*0#fn1 ' int2str(formants.aeF1) '#fn2 ' int2str(formants.aeF2) '%no perturbation'];
			baselineText = baselineText';
		
		elseif strcmp(basestudy, 'ds')
			% text for the same sound/two configurations
			baselineText{1} = '1';
			baselineText{2} = 'Произноси слоги и тяни гласные пока рамка зелёная.';
			baselineText{3} = 'Aufgabenbeschreibung'; 
			baselineText{4} = 'ди';
			baselineText{5} = ['i_1_0000_01_REP#fb 1#pertAmp 0#pertPhi pi*0#fn1 ' int2str(formants.iF1) '#fn2 ' int2str(formants.iF2) '%no perturbation'];
			baselineText{6} = 'ды';
			baselineText{7} = ['due_1_0000_02_REP#fb 1#pertAmp 0#pertPhi pi*0#fn1 ' int2str(formants.ueF1) '#fn2 ' int2str(formants.ueF2) '%no perturbation'];
			baselineText{8} = 'гы';
			baselineText{9} = ['gue_1_0000_03_REP#fb 1#pertAmp 0#pertPhi pi*0#fn1 ' int2str(formants.ueF1) '#fn2 ' int2str(formants.ueF2) '%no perturbation'];
			baselineText{10} = 'гу';
			baselineText{11} = ['u_1_0000_04_REP#fb 1#pertAmp 0#pertPhi pi*0#fn1 ' int2str(formants.uF1) '#fn2 ' int2str(formants.uF2) '%no perturbation'];
			baselineText = baselineText';
		
		elseif strcmp(basestudy, 'vs')
			% text for the vowel shifting
			baselineText{1} = '1';
			baselineText{2} = 'Bitte artikuliere und "ziehe" die Vokale solange der Rahmen grün bleibt.';
			baselineText{3} = 'Aufgabenbeschreibung'; 
			baselineText{4} = 'i';
			baselineText{5} = ['i_1_0000_01_REP#fb 1#pertAmp 0#pertPhi pi*0#fn1 ' int2str(formants.iF1) '#fn2 ' int2str(formants.iF2) '%no perturbation'];
			baselineText{6} = 'e';
			baselineText{7} = ['e_1_0000_02_REP#fb 1#pertAmp 0#pertPhi pi*0#fn1 ' int2str(formants.eF1) '#fn2 ' int2str(formants.eF2) '%no perturbation'];
			baselineText{8} = 'ä';
			baselineText{9} = ['ae_1_0000_03_REP#fb 1#pertAmp 0#pertPhi pi*0#fn1 ' int2str(formants.aeF1) '#fn2 ' int2str(formants.aeF2) '%no perturbation'];
			% baselineText{6} = 'ng';
			% baselineText{7} = ['an_1_0000_02_REP#fb 1#pertAmp 0#pertPhi pi*0#fn1 ' int2str(formants.anF1) '#fn2 ' int2str(formants.anF2) '%no perturbation'];
			baselineText{10} = 'a';
			baselineText{11} = ['a_1_0000_04_REP#fb 1#pertAmp 0#pertPhi pi*0#fn1 ' int2str(formants.aF1) '#fn2 ' int2str(formants.aF2) '%no perturbation'];
			baselineText = baselineText';
		end

		% check if the base stim file for that ID already exists
		overwrite = 'N';
		if exist(fullfile(phaseFolder, ['stimfile_base.txt']), 'file') && overwrite == 'N';
	  		overwrite=input('A base stimfile is already in place! Overwrite? (Y/N): ', 's');
	    	if strcmp(overwrite, 'N') || strcmp(overwrite, 'n')
	      		disp('Kept original file. Check it and proceed...');
	      
	    	else
	    		%(fullfile(phaseFolder, ['stimfile_base.txt']));
	    		stimid=fopen(fullfile(phaseFolder, ['stimfile_base.txt']),'wt');
	    		for l = 1:length(baselineText)
					if l ~= length(baselineText)
						fprintf(stimid, '%s\n', baselineText{l});
					else
						fprintf(stimid, '%s', baselineText{l});
					end
				end
	    	end
		else    
	    	stimid=fopen(fullfile(phaseFolder, ['stimfile_base.txt']),'wt');
	    	for l = 1:length(baselineText)
				if l ~= length(baselineText)
					fprintf(stimid, '%s\n', baselineText{l});
				else
					fprintf(stimid, '%s', baselineText{l});
				end
			end
		end
		
		% number of repetitions of vowels
		repetitions = 15;

		if strcmp(basestudy, 'ns')
			makeNewStimfile(subjectID, phaseFolder, phaseFolder, repetitions);
		else
			makeNewStimfileNofill(subjectID, phaseFolder, phaseFolder, repetitions);
		end
	end