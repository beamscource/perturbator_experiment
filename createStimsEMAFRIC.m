function createStimsEMAFRIC(subjectFolder, gender, formants, pertSet, phase)

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

	subjectID = folderParts{5}; % changed 4 to 5 since 1 more subfolder

	if strcmp(phase, 'familiarization')

		txtStruct{1} = '1';
		txtStruct{2} = 'Sprechen Sie, solange der Rahmen grün ist.';
		txtStruct{3} = ['Aufgabenbeschreibung#0' phase '#blank#blank']; 
		txtStruct{4} = 'Vanessa stieß heißen Kessel um.';
		txtStruct{5} = ['ls_1_0000_01_REP#fb 1#pertAmp 0#pertPhi pi*0%familiarization'];
		txtStruct{6} = 'Strauße essen nasse Nesseln.';
		txtStruct{7} = ['ts_1_0000_01_REP#fb 1#pertAmp 0#pertPhi pi*0%familiarization'];
		txtStruct{8} = 'Klaus saß im weißen Sessel.';
		txtStruct{9} = ['us_1_0000_01_REP#fb 1#pertAmp 0#pertPhi pi*0%familiarization'];
		txtStruct{10} = 'Die Maus frisst süßen Mais.';
		txtStruct{11} = ['ms_1_0000_01_REP#fb 1#pertAmp 0#pertPhi pi*0%familiarization'];
		txtStruct{12} = 'Lars vergoss ein Glas Wasser.';
		txtStruct{13} = ['rs_1_0000_01_REP#fb 1#pertAmp 0#pertPhi pi*0%familiarization'];
		txtStruct{14} = 'Saskia und Ines gießen Narzissen.';
		txtStruct{15} = ['as_1_0000_01_REP#fb 1#pertAmp 0#pertPhi pi*0%familiarization'];
		txtStruct = txtStruct';
		
		% number of repetitions of each stimulus
		repetitions = 4;

		makeNewStimfile(subjectID, subjectFolder, txtStruct, repetitions, nLPC, f0, language);

	elseif strcmp(phase, 'baseline')

		txtStruct{1} = '1';
		txtStruct{2} = 'Sprechen Sie, solange der Rahmen grün ist.';
		txtStruct{3} = ['Aufgabenbeschreibung#1' phase '#blank#blank']; 
		txtStruct{4} = 'Lasse erhielt eine Tasse.';
		txtStruct{5} = ['ls_1_0000_01_REP#fb 1#pertAmp 0#pertPhi pi*0%no perturbation'];
		txtStruct = txtStruct';
		
		% number of repetitions of words
		repetitions = 32;

		makeNewStimfile(subjectID, subjectFolder, txtStruct, repetitions, nLPC, f0, language);

	elseif strcmp(phase, 'post')

		txtStruct{1} = '1';
		txtStruct{2} = 'Sprechen Sie, solange der Rahmen grün ist.';
		txtStruct{3} = ['Aufgabenbeschreibung#5' phase '#blank#blank']; 
		txtStruct{4} = 'Lasse erhielt eine Tasse.';
		txtStruct{5} = ['ls_1_0000_01_REP#fb 1#pertAmp 0#pertPhi pi*0%no perturbation'];
		txtStruct = txtStruct';
		
		% number of repetitions of words
		repetitions = 32;

		makeNewStimfile(subjectID, subjectFolder, txtStruct, repetitions, nLPC, f0, language);
	else % stimfiles for shift phase

		phasesList = pertSet.phases;

		for i = 1:length(phasesList)

			fields = fieldnames(pertSet);

			phase = phasesList{i};

			pertSettings = pertSet.(fields{i});

			txtStruct{1} = '1';
			txtStruct{2} = 'Sprechen Sie, solange der Rahmen grün ist.';
			txtStruct{3} = ['Aufgabenbeschreibung#' phase '#blank#blank'];
			txtStruct{4} = 'Lasse erhielt eine Tasse.';
			txtStruct{5} = ['ls_1_0000_01_REP#fb 1#pertAmp 0#pertPhi pi*0' pertSettings]; 
			txtAStruct = txtStruct';

			% number of repetition per word
			repetitions = 32;
			
			makeNewStimfile(subjectID, subjectFolder, txtStruct, repetitions, nLPC, f0, language);
		end
	end
end