function createStimsDS(subjectFolder, gender, formants, pertSet, phase)

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

	subjectID = folderParts{5};

	if strcmp(phase, 'baseline')

		txtStruct{1} = '1';
		txtStruct{2} = 'Произносите слоги и тяните гласный, пока рамка зелёная.';
		txtStruct{3} = ['Aufgabenbeschreibung ' phase]; 
		txtStruct{4} = 'ди';
		txtStruct{5} = ['di_1_0000_01_REP#fb 1#pertAmp 0#pertPhi pi*0#fn1 ' int2str(formants.iF1) '#fn2 ' int2str(formants.iF2) '%no perturbation'];
		txtStruct{6} = 'ды';
		txtStruct{7} = ['dy_1_0000_02_REP#fb 1#pertAmp 0#pertPhi pi*0#fn1 ' int2str(formants.yF1) '#fn2 ' int2str(formants.yF2) '%no perturbation'];
		txtStruct{8} = 'гы';
		txtStruct{9} = ['gy_1_0000_03_REP#fb 1#pertAmp 0#pertPhi pi*0#fn1 ' int2str(formants.yF1) '#fn2 ' int2str(formants.yF2) '%no perturbation'];
		txtStruct{10} = 'гу';
		txtStruct{11} = ['gu_1_0000_04_REP#fb 1#pertAmp 0#pertPhi pi*0#fn1 ' int2str(formants.uF1) '#fn2 ' int2str(formants.uF2) '%no perturbation'];
		txtStruct = txtStruct';
		
		% number of repetitions of vowels
		repetitions = 15;
		makeNewStimfile(subjectID, subjectFolder, txtStruct, repetitions, nLPC, f0, language);

	else

		fields = fieldnames(pertSet);

		for i = 1:2:length(fields)

			% % get phase from the perturbation settings
			phaseString = fields(i);
			
			loop = 0;
        	while 1
            	[token, phaseString] = strtok(phaseString, '_');
            	loop = loop + 1;
            	if loop == 2, break; end
        	end

			phase = token{1};
		
			[pertSettingsA1, pertSettingsA2] = strtok(pertSet.(fields{i}), '%');
			[pertSettingsB1, pertSettingsB2] = strtok(pertSet.(fields{i+1}), '%');

			txtStruct{1} = '1';
			txtStruct{2} = 'Произносите слоги и тяните гласный, пока рамка зелёная.';
			txtStruct{3} = ['Aufgabenbeschreibung ' phase];
			txtStruct{4} = 'ды';
			txtStruct{5} = ['dy_1_0000_01_REP#fb 1' pertSettingsA1 '#fn1 ' int2str(formants.iF1) '#fn2 ' int2str(formants.iF2) pertSettingsA2]; 
			txtStruct{6} = 'гы';
			txtStruct{7} = ['gy_1_0000_02_REP#fb 1' pertSettingsB1  '#fn1 ' int2str(formants.uF1) '#fn2 ' int2str(formants.uF2) pertSettingsB2];
			txtStruct = txtStruct';

			% number of repetition per vowel
			repetitions = 25;

			makeNewStimfile(subjectID, subjectFolder, txtStruct, repetitions, nLPC, f0, language);
		end
	end
end