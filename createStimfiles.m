function createStimfiles(subjectFolder, pertSet, formants)

	% function to create base_stim files for each phase (tryouts, learning (experiment 1),
	% articulatory pressure (experiment 2)); base stim for baseline should be already in 
	% the data folder
	% calling makeNewStimfile(vp, subjectfolder, phasefolder, repetitions, gender)
	% to make randomized versions of stim files for each experimental phase

	if ~exist('nlpc', 'var')
	    nlpc = input('Number of LPC coefficients? (male 17-19, female 15-17) : ','s');
	    nlpc = str2double(nlpc);
	end

	if ~exist('f0', 'var')
	    f0 = input('Fundamental frequency? (male 110-150, female 200-250): ','s');
	    f0 = str2double(f0);
	end

	% get subjectID from the subjectFolder
	folderString = subjectFolder;

	i = 1;
	while 1
	    [str, folderString] = strtok(folderString, '\');
	    if isempty(str),  break;  end
	       folderParts{i} = sprintf('%s', str);
	       i = i + 1;
	end

	subjectID = folderParts{4};

	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	%% create base stim file and randomized stimulus file for the sound learning experiment
	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	if isfield(pertSet, 'pertSettingsUue') && isfield(pertSet, 'pertSettingsUEi')
		
		phase = 'tryout';
		phaseFolder = fullfile(subjectFolder, phase);
		mkdir(phaseFolder);

		[pertSettingsUEu1, pertSettingsUEu2] = strtok(pertSet.pertSettingsUEu, '%');
		[pertSettingsUue1, pertSettingsUue2] = strtok(pertSet.pertSettingsUue, '%');

		tryoutText{1} = '1';
		tryoutText{2} = 'Bitte artikuliere folgende Vokale. Achte darauf, wie sich deine Artikulation verändert hat.';
		tryoutText{3} = 'Aufgabenbeschreibung'; 
		tryoutText{4} = 'ü';
		tryoutText{5} = ['ue_1_0000_01_REP#fb 1' pertSettingsUEu1 '#fn1 ' int2str(formants.ueF1) '#fn2 ' int2str(formants.ueF2) '#gain 1' pertSettingsUEu2];
		tryoutText{6} = 'u';
		tryoutText{7} = ['u_1_0000_02_REP#fb 1' pertSettingsUue1 '#fn1 ' int2str(formants.uF1) '#fn2 ' int2str(formants.uF2) '#gain 2' pertSettingsUue2];
		tryoutText{8} = 'a';
		tryoutText{9} = ['a_1_0000_03_REP#fb 1#pertAmp 0#pertPhi pi*0#fn1 ' int2str(formants.aF1) '#fn2 ' int2str(formants.aF2) '#gain 1%no perturbation']; 
		tryoutText{10} = 'ä';
		tryoutText{11} = ['ae_1_0000_04_REP#fb 1#pertAmp 0#pertPhi pi*0#fn1 ' int2str(formants.aeF1) '#fn2 ' int2str(formants.aeF2) '#gain 1%no perturbation'];
		tryoutText = tryoutText';

		stimid=fopen(fullfile(phaseFolder, ['stimfile_base.txt']),'wt');
		for l = 1:length(tryoutText)
			if l ~= length(tryoutText)
				fprintf(stimid, '%s\n', tryoutText{l});
			else
				fprintf(stimid, '%s', tryoutText{l});
			end
		end

		% number of repetition per vowel
		repetitions = 120;

		makeNewStimfile(subjectID, phaseFolder, phaseFolder, repetitions, nlpc, f0);

		%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		%% create base stim file and randomized stimulus file for the learning phase
		%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

		phase = 'learning';
		phaseFolder = fullfile(subjectFolder, phase);
		mkdir(phaseFolder);

		learningText{1} = '1';
		learningText{2} = 'Hör bei jedem Trial zu und versuche den gehörten Vokal in einer CV-Silbe zu artikulieren.';
		learningText{3} = 'Aufgabenbeschreibung';
		learningText{4} = 'd*';
		learningText{5} = ['ue_1_0000_01_REP#fb 2' pertSettingsUEu1 '#fn1 ' int2str(formants.ueF1) '#fn2 ' int2str(formants.ueF2) pertSettingsUEu2];
		learningText{6} = 'g*';
		learningText{7} = ['u_1_0000_02_REP#fb 2' pertSettingsUue1 '#fn1 ' int2str(formants.uF1) '#fn2 ' int2str(formants.uF2) pertSettingsUue2];
		learningText = learningText';
    
		stimid=fopen(fullfile(phaseFolder, ['stimfile_base.txt']),'wt');
		for l = 1:length(learningText)
			if l ~= length(learningText)
				fprintf(stimid, '%s\n', learningText{l});
			else
				fprintf(stimid, '%s', learningText{l});
			end
		end

		% number of repetition per vowel
		repetitions = 120;

		makeNewStimfile(subjectID, phaseFolder, phaseFolder, repetitions, nlpc, f0);
	end

	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	%% create base stim file and randomized stimulus file for the double sound experiment
	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	if isfield(pertSet, 'pertSettingsUEi')
		
		phase = 'training';
		phaseFolder = fullfile(subjectFolder, phase);
		mkdir(phaseFolder);
		keyboard
		[pertSettingsUEi1, pertSettingsUEi2] = strtok(pertSet.pertSettingsUEi, '%');
		[pertSettingsUEu1, pertSettingsUEu2] = strtok(pertSet.pertSettingsUEu, '%');

		trainingText{1} = '1';
		trainingText{2} = 'Произноси слоги и тяни гласные пока рамка зелёная.';
		trainingText{3} = 'Aufgabenbeschreibung';
		trainingText{4} = 'ды';
		trainingText{5} = ['due_1_0000_01_REP#fb 1' pertSettingsUEu1 '#fn1 ' int2str(formants.iF1) '#fn2 ' int2str(formants.iF2) pertSettingsUEu2]; 
		trainingText{6} = 'гы';
		trainingText{7} = ['gue_1_0000_02_REP#fb 1' pertSettingsUEi1  '#fn1 ' int2str(formants.uF1) '#fn2 ' int2str(formants.uF2) pertSettingsUEi2];
		trainingText = trainingText';

		stimid=fopen(fullfile(phaseFolder, ['stimfile_base.txt']),'wt');
		for l = 1:length(trainingText)
			if l ~= length(trainingText)
				fprintf(stimid, '%s\n', trainingText{l});
			else
				fprintf(stimid, '%s', trainingText{l});
			end
		end


		% number of repetition per vowel
		repetitions = 60;

		makeNewStimfileNofill(subjectID, phaseFolder, phaseFolder, repetitions, nlpc, f0);

		phase = 'test';
		phaseFolder = fullfile(subjectFolder, phase);
		mkdir(phaseFolder);

		testText{1} = '1';
		testText{2} = 'Произноси слоги и тяни гласные пока рамка зелёная.';
		testText{3} = 'Aufgabenbeschreibung';
		testText{4} = 'ды';
		testText{5} = ['due_1_0000_01_REP#fb 1' pertSettingsUEu1 '#fn1 ' int2str(formants.iF1) '#fn2 ' int2str(formants.iF2) pertSettingsUEu2]; 
		testText{6} = 'гы';
		testText{7} = ['gue_1_0000_02_REP#fb 1' pertSettingsUEi1  '#fn1 ' int2str(formants.uF1) '#fn2 ' int2str(formants.uF2) pertSettingsUEi2];
		testText = testText';

		stimid=fopen(fullfile(phaseFolder, ['stimfile_base.txt']),'wt');
		for l = 1:length(testText)
			if l ~= length(testText)
				fprintf(stimid, '%s\n', testText{l});
			else
				fprintf(stimid, '%s', testText{l});
			end
		end


		% number of repetition per vowel
		repetitions = 20;

		makeNewStimfileNofill(subjectID, phaseFolder, phaseFolder, repetitions, nlpc, f0);
	end

	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	%% create base stim file and randomized stimulus file for the vowelshift experiment
	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	if isfield(pertSet, 'pertSettingsAE')
		phase = 'vowelshift';
		phaseFolder = fullfile(subjectFolder, phase);
		mkdir(phaseFolder);

		[pertSettingsE1, pertSettingsE2] = strtok(pertSet.pertSettingsE, '%');
		[pertSettingsAE1, pertSettingsAE2] = strtok(pertSet.pertSettingsAE, '%');

		vowelshiftText{1} = '1';
		vowelshiftText{2} = 'Bitte artikuliere und "ziehe" die Vokale solange der Rahmen grün bleibt.';
		vowelshiftText{3} = 'Aufgabenbeschreibung';
		vowelshiftText{4} = 'e';
		vowelshiftText{5} = ['e_1_0000_02_REP#fb 1' pertSettingsE1 '#fn1 ' int2str(formants.eF1) '#fn2 ' int2str(formants.eF2) pertSettingsE2]; 
		vowelshiftText{6} = 'ä';
		vowelshiftText{7} = ['ae_1_0000_03_REP#fb 1#pertAmp 0#pertPhi pi*0#fn1 ' int2str(formants.aeF1) '#fn2 ' int2str(formants.aeF2) '%no perturbation'];
		vowelshiftText{8} = 'i';
		vowelshiftText{9} = ['i_1_0000_01_REP#fb 1#pertAmp 0#pertPhi pi*0#fn1 ' int2str(formants.iF1) '#fn2 ' int2str(formants.iF2) '%no perturbation']; 
		vowelshiftText{10} = 'a';
		vowelshiftText{11} = ['a_1_0000_04_REP#fb 1#pertAmp 0#pertPhi pi*0#fn1 ' int2str(formants.aF1) '#fn2 ' int2str(formants.aF2) '%no perturbation'];
		vowelshiftText = vowelshiftText';

		stimid=fopen(fullfile(phaseFolder, ['stimfile_base.txt']),'wt');
		for l = 1:length(vowelshiftText)
			if l ~= length(vowelshiftText)
				fprintf(stimid, '%s\n', vowelshiftText{l});
			else
				fprintf(stimid, '%s', vowelshiftText{l});
			end
		end


		% number of repetition per vowel
		repetitions = 20;

		makeNewStimfile(subjectID, phaseFolder, phaseFolder, repetitions, nlpc, f0);

		phase = 'doubleshift';
		phaseFolder = fullfile(subjectFolder, phase);
		mkdir(phaseFolder);

		doubleshiftText{1} = '1';
		doubleshiftText{2} = 'Bitte artikuliere und "ziehe" die Vokale solange der Rahmen grün bleibt.';
		doubleshiftText{3} = 'Aufgabenbeschreibung';
		doubleshiftText{4} = 'e';
		doubleshiftText{5} = ['e_1_0000_02_REP#fb 1' pertSettingsE1 '#fn1 ' int2str(formants.eF1) '#fn2 ' int2str(formants.eF2) pertSettingsE2]; 
		doubleshiftText{6} = 'ä';
		doubleshiftText{7} = ['ae_1_0000_03_REP#fb 1' pertSettingsAE1 '#fn1 ' int2str(formants.aeF1) '#fn2 ' int2str(formants.aeF2) pertSettingsAE2];
		doubleshiftText{8} = 'i';
		doubleshiftText{9} = ['i_1_0000_01_REP#fb 1#pertAmp 0#pertPhi pi*0#fn1 ' int2str(formants.iF1) '#fn2 ' int2str(formants.iF2) '%no perturbation']; 
		doubleshiftText{10} = 'a';
		doubleshiftText{11} = ['a_1_0000_04_REP#fb 1#pertAmp 0#pertPhi pi*0#fn1 ' int2str(formants.aF1) '#fn2 ' int2str(formants.aF2) '%no perturbation'];
		doubleshiftText = doubleshiftText';

		stimid=fopen(fullfile(phaseFolder, ['stimfile_base.txt']),'wt');
		for l = 1:length(doubleshiftText)
			if l ~= length(doubleshiftText)
				fprintf(stimid, '%s\n', doubleshiftText{l});
			else
				fprintf(stimid, '%s', doubleshiftText{l});
			end
		end


		% number of repetition per vowel
		repetitions = 50;

		makeNewStimfile(subjectID, phaseFolder, phaseFolder, repetitions, nlpc, f0);

	end
end