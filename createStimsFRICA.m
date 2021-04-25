function createStimsFRICA(subjectFolder, gender, formants, pertSet, phase)

	% function to create randomized, subject specific, stim files for several phases

	if nargin < 5
		phase = [];
	end

	if nargin < 4
		pertSet = {};
	end

	if ~exist('gender', 'var')
    	gender = input('Participant''s gender? (m/f): ','s');
	end

	if strcmp(gender, 'm')
	    nLPC = 19;
	    f0 = 120;
	elseif strcmp(gender, 'f')
		nLPC = 17;
		f0 = 220;
	end

	language = 'r';

	% get subjectID from the subjectFolder
	folderString = subjectFolder;

	i = 1;
	while 1
	    [str, folderString] = strtok(folderString, '\');
	    if isempty(str),  break;  end
	       folderParts{i} = sprintf('%s', str);
	       i = i + 1;
	end

	subjectID = folderParts{5}; % changed 4 to 5 since 1 more subfolder

	if strcmp(phase, 'baseline')

		txtStruct{1} = '1';
		txtStruct{2} = 'Произноси слова когда рамка зелёная.';
		txtStruct{3} = ['Aufgabenbeschreibung 1' phase]; 
		txtStruct{4} = 'лес';
		txtStruct{5} = ['ls_1_0000_01_REP#fb 1#pertAmp 0#pertPhi pi*0%no perturbation'];
		txtStruct{6} = 'вес';
		txtStruct{7} = ['vs_1_0000_02_REP#fb 1#pertAmp 0#pertPhi pi*0%no perturbation'];
		txtStruct{8} = 'лезь';
		txtStruct{9} = ['lsj_1_0000_03_REP#fb 1#pertAmp 0#pertPhi pi*0%no perturbation'];
		txtStruct{10} = 'весь';
		txtStruct{11} = ['vsj_1_0000_04_REP#fb 1#pertAmp 0#pertPhi pi*0%no perturbation'];
		txtStruct{12} = 'вещь';
		txtStruct{13} = ['vSj_1_0000_05_REP#fb 1#pertAmp 0#pertPhi pi*0%no perturbation'];
		txtStruct{14} = 'лещ';
		txtStruct{15} = ['lSj_1_0000_06_REP#fb 1#pertAmp 0#pertPhi pi*0%no perturbation'];
		txtStruct = txtStruct';
		
		% number of repetitions of words
		repetitions = 8;

		makeNewStimfile(subjectID, subjectFolder, txtStruct, repetitions, nLPC, f0, language);

	else % stimfiles for shift phases and test phases

		fields = fieldnames(pertSet);

		% a 5 trial ramp at the beginning of the training block ist included in makeNewStimfileFRICramp
		for i = [1]

			%% training block

			% % get phase from the perturbation settings
			phaseString = fields(i);
			
			loop = 0;
        	while 1
            	[token, phaseString] = strtok(phaseString, '_');
            	loop = loop + 1;
            	if loop == 2, break; end
        	end

			phase = token{1};
			
			pertSettingsA = pertSet.(fields{i});
			pertSettingsB = pertSet.(fields{i+1});

			txtStruct{1} = '1';
			txtStruct{2} = 'Произноси слова когда рамка зелёная.';
			txtStruct{3} = ['Aufgabenbeschreibung ' phase '_training'];
			txtStruct{4} = 'лезь';
			txtStruct{5} = ['lsj_1_0000_01_REP#fb 1#pertAmp 0#pertPhi pi*0' pertSettingsA]; 
			txtStruct{6} = 'весь';
			txtStruct{7} = ['vsj_1_0000_02_REP#fb 1#pertAmp 0#pertPhi pi*0' pertSettingsB];
			txtAStruct = txtStruct';

			% number of repetition per word
			repetitionsA = 20; %less repetitions?
			clear txtStruct

			%% testing block
			txtStruct{1} = 'Произноси слова когда рамка зелёная. Необращай внимания на шум.';
			txtStruct{2} = ['Aufgabenbeschreibung ' phase '_masked'];
			txtStruct{3} = 'лес';
			txtStruct{4} = ['ls_1_0000_01_REP#fb 2#pertAmp 0#pertPhi pi*0%masked feedback'];
			txtStruct{5} = 'вес';
			txtStruct{6} = ['vs_1_0000_02_REP#fb 2#pertAmp 0#pertPhi pi*0%masked feedback'];
			txtStruct{7} = 'лезь';
			txtStruct{8} = ['lsj_1_0000_03_REP#fb 2#pertAmp 0#pertPhi pi*0%masked feedback'];
			txtStruct{9} = 'весь';
			txtStruct{10} = ['vsj_1_0000_04_REP#fb 2#pertAmp 0#pertPhi pi*0%masked feedback'];
			txtStruct{11} = 'вещь';
			txtStruct{12} = ['vSj_1_0000_05_REP#fb 2#pertAmp 0#pertPhi pi*0%masked feedback'];
			txtStruct{13} = 'лещ';
			txtStruct{14} = ['lSj_1_0000_06_REP#fb 2#pertAmp 0#pertPhi pi*0%masked feedback'];
			txtBStruct = txtStruct';

			% number of repetition per vowel
			repetitionsB = 4;
			clear txtStruct

			makeNewStimfileFRICramp(subjectID, subjectFolder, txtAStruct, repetitionsA, txtBStruct, repetitionsB, nLPC, f0, language);
		end

		% no ramp at the beginning of training blocks
		for i = [5, 9] % two blocks

			%% training block

			% % get phase from the perturbation settings
			phaseString = fields(i);
			
			loop = 0;
        	while 1
            	[token, phaseString] = strtok(phaseString, '_');
            	loop = loop + 1;
            	if loop == 2, break; end
        	end

			phase = token{1};
			
			pertSettingsA = pertSet.(fields{i});
			pertSettingsB = pertSet.(fields{i+1});

			txtStruct{1} = '1';
			txtStruct{2} = 'Произноси слова когда рамка зелёная.';
			txtStruct{3} = ['Aufgabenbeschreibung ' phase '_training'];
			txtStruct{4} = 'лезь';
			txtStruct{5} = ['lsj_1_0000_01_REP#fb 1#pertAmp 0#pertPhi pi*0' pertSettingsA]; 
			txtStruct{6} = 'весь';
			txtStruct{7} = ['vsj_1_0000_02_REP#fb 1#pertAmp 0#pertPhi pi*0' pertSettingsB];
			txtAStruct = txtStruct';

			% number of repetition per word
			repetitionsA = 20; %less repetitions?
			clear txtStruct

			%% testing block
			txtStruct{1} = 'Произноси слова когда рамка зелёная. Необращай внимания на шум.';
			txtStruct{2} = ['Aufgabenbeschreibung ' phase '_masked'];
			txtStruct{3} = 'лес';
			txtStruct{4} = ['ls_1_0000_01_REP#fb 2#pertAmp 0#pertPhi pi*0%masked feedback'];
			txtStruct{5} = 'вес';
			txtStruct{6} = ['vs_1_0000_02_REP#fb 2#pertAmp 0#pertPhi pi*0%masked feedback'];
			txtStruct{7} = 'лезь';
			txtStruct{8} = ['lsj_1_0000_03_REP#fb 2#pertAmp 0#pertPhi pi*0%masked feedback'];
			txtStruct{9} = 'весь';
			txtStruct{10} = ['vsj_1_0000_04_REP#fb 2#pertAmp 0#pertPhi pi*0%masked feedback'];
			txtStruct{11} = 'вещь';
			txtStruct{12} = ['vSj_1_0000_05_REP#fb 2#pertAmp 0#pertPhi pi*0%masked feedback'];
			txtStruct{13} = 'лещ';
			txtStruct{14} = ['lSj_1_0000_06_REP#fb 2#pertAmp 0#pertPhi pi*0%masked feedback'];
			txtBStruct = txtStruct';

			% number of repetition per vowel
			repetitionsB = 4;
			clear txtStruct

			makeNewStimfileFRIC(subjectID, subjectFolder, txtAStruct, repetitionsA, txtBStruct, repetitionsB, nLPC, f0, language);
		end
	end
end