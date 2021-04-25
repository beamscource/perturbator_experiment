function createStimsLS(subjectFolder, gender, formants, pertSet, phase)

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

	language = 'g';

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

	if strcmp(phase, 'baseline')

		txtStruct{1} = '1';
		txtStruct{2} = 'Spreche die Silben und ‚ziehe‘ die Vokale solange der Rahmen grün bleibt.';
		txtStruct{3} = ['Aufgabenbeschreibung ' '1_' phase]; 
		txtStruct{4} = 'dü';
		txtStruct{5} = ['dy_1_0000_01_REP#fb 1#pertAmp 0#pertPhi pi*0#fn1 ' int2str(formants.yF1) '#fn2 ' int2str(formants.yF2) '%no perturbation'];
		txtStruct{6} = 'du';
		txtStruct{7} = ['du_1_0000_02_REP#fb 1#pertAmp 0#pertPhi pi*0#fn1 ' int2str(formants.uF1) '#fn2 ' int2str(formants.uF2) '%no perturbation'];
		txtStruct{8} = 'gü';
		txtStruct{9} = ['gy_1_0000_03_REP#fb 1#pertAmp 0#pertPhi pi*0#fn1 ' int2str(formants.yF1) '#fn2 ' int2str(formants.yF2) '%no perturbation'];
		txtStruct{10} = 'gu';
		txtStruct{11} = ['gu_1_0000_04_REP#fb 1#pertAmp 0#pertPhi pi*0#fn1 ' int2str(formants.uF1) '#fn2 ' int2str(formants.uF2) '%no perturbation'];
		txtStruct{12} = 'mü';
		txtStruct{13} = ['my_1_0000_04_REP#fb 1#pertAmp 0#pertPhi pi*0#fn1 ' int2str(formants.yF1) '#fn2 ' int2str(formants.yF2) '%no perturbation'];
		txtStruct{14} = 'mu';
		txtStruct{15} = ['mu_1_0000_04_REP#fb 1#pertAmp 0#pertPhi pi*0#fn1 ' int2str(formants.uF1) '#fn2 ' int2str(formants.uF2) '%no perturbation'];
		txtStruct{16} = 'bü';
		txtStruct{17} = ['by_1_0000_04_REP#fb 1#pertAmp 0#pertPhi pi*0#fn1 ' int2str(formants.yF1) '#fn2 ' int2str(formants.yF2) '%no perturbation'];
		txtStruct{18} = 'bu';
		txtStruct{19} = ['bu_1_0000_04_REP#fb 1#pertAmp 0#pertPhi pi*0#fn1 ' int2str(formants.uF1) '#fn2 ' int2str(formants.uF2) '%no perturbation'];
		txtStruct{20} = 'tü';
		txtStruct{21} = ['ty_1_0000_04_REP#fb 1#pertAmp 0#pertPhi pi*0#fn1 ' int2str(formants.yF1) '#fn2 ' int2str(formants.yF2) '%no perturbation'];
		txtStruct{22} = 'tu';
		txtStruct{23} = ['tu_1_0000_04_REP#fb 1#pertAmp 0#pertPhi pi*0#fn1 ' int2str(formants.uF1) '#fn2 ' int2str(formants.uF2) '%no perturbation'];
		txtStruct{24} = 'kü';
		txtStruct{25} = ['ky_1_0000_04_REP#fb 1#pertAmp 0#pertPhi pi*0#fn1 ' int2str(formants.yF1) '#fn2 ' int2str(formants.yF2) '%no perturbation'];
		txtStruct{26} = 'ku';
		txtStruct{27} = ['ku_1_0000_04_REP#fb 1#pertAmp 0#pertPhi pi*0#fn1 ' int2str(formants.uF1) '#fn2 ' int2str(formants.uF2) '%no perturbation'];
		txtStruct = txtStruct';
		
		% number of repetitions of vowels
		repetitions = 6;
		makeNewStimfile(subjectID, subjectFolder, txtStruct, repetitions, nLPC, f0, language);
		% or make two parts baseline by making two txt-files

	else % stim files for training (first loop) and test blocks (second loop)

		fields = fieldnames(pertSet);

		for i = [1, 5]

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
			txtStruct{2} = 'Spreche die Silben und ‚ziehe‘ die Vokale solange der Rahmen grün bleibt.';
			txtStruct{3} = ['Aufgabenbeschreibung ' phase];
			txtStruct{4} = 'dü';
			txtStruct{5} = ['dy_1_0000_01_REP#fb 1' pertSettingsA1 '#fn1 ' int2str(formants.yF1) '#fn2 ' int2str(formants.yF2) pertSettingsA2]; 
			txtStruct{6} = 'gu';
			txtStruct{7} = ['gu_1_0000_02_REP#fb 1' pertSettingsB1  '#fn1 ' int2str(formants.uF1) '#fn2 ' int2str(formants.uF2) pertSettingsB2];
			txtStruct{8} = 'mü';
			txtStruct{9} = ['my_1_0000_01_REP#fb 1#fn1 ' int2str(formants.yF1) '#fn2 ' int2str(formants.yF2) '%no perturbation']; 
			txtStruct{10} = 'mu';
			txtStruct{11} = ['mu_1_0000_02_REP#fb 1#fn1 ' int2str(formants.uF1) '#fn2 ' int2str(formants.uF2) '%no perturbation'];
			txtStruct{12} = 'bü';
			txtStruct{13} = ['by_1_0000_01_REP#fb 1#fn1 ' int2str(formants.yF1) '#fn2 ' int2str(formants.yF2) '%no perturbation']; 
			txtStruct{14} = 'bu';
			txtStruct{15} = ['bu_1_0000_02_REP#fb 1#fn1 ' int2str(formants.uF1) '#fn2 ' int2str(formants.uF2) '%no perturbation'];
			txtStruct = txtStruct';

			% number of repetition per vowel
			repetitions = [14 5];

			makeNewStimfileAsym(subjectID, subjectFolder, txtStruct, repetitions, nLPC, f0, language);
		end

		for i = [3, 7]

			% % get phase from the perturbation settings
			phaseString = fields(i);
			
			loop = 0;
        	while 1
            	[token, phaseString] = strtok(phaseString, '_');
            	loop = loop + 1;
            	if loop == 2, break; end
        	end

			phase = token{1};

			txtStruct{1} = '1';
			txtStruct{2} = 'Spreche die Silben mit dem gehörten Vokal aus und ‚ziehe‘ diesen solange der Rahmen grün bleibt.';
			txtStruct{3} = ['Aufgabenbeschreibung ' phase];
			txtStruct{4} = 'd..';
			txtStruct{5} = ['d_1_0000_01_REP#fb 2#fn1 ' int2str(formants.yF1) '#fn2 ' int2str(formants.yF2) '%no perturbation']; 
			txtStruct{6} = 'g..';
			txtStruct{7} = ['g_1_0000_02_REP#fb 2#fn1 ' int2str(formants.uF1) '#fn2 ' int2str(formants.uF2) '%no perturbation'];
			txtStruct{8} = 'm..';
			txtStruct{9} = ['m_1_0000_01_REP#fb 2#fn1 ' int2str(formants.yF1) '#fn2 ' int2str(formants.yF2) '%no perturbation']; 
			txtStruct{12} = 'b..';
			txtStruct{13} = ['b_1_0000_01_REP#fb 2#fn1 ' int2str(formants.yF1) '#fn2 ' int2str(formants.yF2) '%no perturbation']; 
			txtStruct{14} = 't..';
			txtStruct{15} = ['t_1_0000_02_REP#fb 2#fn1 ' int2str(formants.uF1) '#fn2 ' int2str(formants.uF2) '%no perturbation'];
			txtStruct{16} = 'k..';
			txtStruct{17} = ['k_1_0000_02_REP#fb 2#fn1 ' int2str(formants.uF1) '#fn2 ' int2str(formants.uF2) '%no perturbation'];
			txtStruct = txtStruct';

			% number of repetition per vowel
			repetitions = 12;

			makeNewStimfile(subjectID, subjectFolder, txtStruct, repetitions, nLPC, f0, language);
		end
	end
end