function [subjectFolder, gender] = perturbatorDS(subjectID, gender, vers, loops)
	% the main Perturbator fuction looping phases of the experiment
	% set-up paths to stimuli, data, and experimental log files 
	% provides start/stop functions for audapter_ctrl
	% settings like trial duration etc can be provided here as a field for
	% prompter_parallel_main
	% calls prompter_parallel_main to start the promting loop

	if nargin < 4
		loops = [];
	end

	experimentFolder = 'D:\perturbator\doublesound';
	data  = 'data';
	dataFolder = fullfile(experimentFolder, data);
	subjectFolder = ['ds_' vers '_' subjectID];
	subjectFolder = fullfile(experimentFolder, data, subjectFolder);

	if ~exist('gender', 'var')
		gender = input('Participant''s gender (m/f): ','s');
	end

	if isempty(gender)
		gender = input('Participant''s gender (m/f): ','s');
	end

	% overwrite = 'N';
	% % check if a folder for that ID already exists
	% if phase == 0 && exist(subjectFolder, 'dir') && overwrite == 'N';
	%   overwrite=input('Folder already in place! Overwrite? (Y/N): ', 's');
	%     if strcmp(overwrite, 'N') || strcmp(overwrite, 'n')
	%       subjectID=input('Chose new ID. Participant''s ID number: ', 's');
	%       subjectFolder = fullfile(experimentFolder, data, subjectID);
	%     else
	%     	rmdir(fullfile(subjectFolder), 's');
	%     	mkdir(subjectFolder);
	%     end
	% end

	if ~exist(subjectFolder, 'dir')
		mkdir(subjectFolder);
		dummyFileID = fopen(fullfile(subjectFolder, ['soundcheck_' subjectID '.txt']),'wt');
		fclose(dummyFileID);
	end

	% find all stim files in the subjectFolder
	fileList = dir([subjectFolder, '\*.txt']);

	if ~isempty(loops)
		last = loops;
	else
		last = length(fileList);
	end
	
	for file = 1:last

		fileName = fileList(file).name;

		% get phase name from the stim file name:
        % create the phase folder
        phase = strtok(fileName, '_');
        phaseFolder = fullfile(subjectFolder, phase);
        
        if exist(phaseFolder, 'dir')
        	continue
        else
        	mkdir(phaseFolder);
        end
        
        % create separate folder for analysis and signal data
		analysis = 'analysis';
		signal = 'signal';
		analysisFolder = fullfile(phaseFolder, analysis);
		signalFolder = fullfile (phaseFolder, signal);
		mkdir(analysisFolder);
		mkdir(signalFolder);

		if strcmp(phase, 'soundcheck')

			if ~exist('language', 'var')
				language = input('Participant''s language (r/g): ','s');
			end

			if strcmp(gender, 'm') && strcmp(language, 'r')
				stimFile = fullfile(experimentFolder, ['soundcheck_m_r.txt']);
			elseif strcmp(gender, 'm') && strcmp(language, 'g')
				stimFile = fullfile(experimentFolder, ['soundcheck_m_g.txt']);
			elseif strcmp(gender, 'f') && strcmp(language, 'r')
				stimFile = fullfile(experimentFolder, ['soundcheck_f_r.txt']);
			elseif strcmp(gender, 'f') && strcmp(language, 'g')
				stimFile = fullfile(experimentFolder, ['soundcheck_f_g.txt']);
			end
		else
			stimFile = fullfile(subjectFolder, fileName);
		end

		logFile = fullfile(phaseFolder, [phase '_' subjectID '_log.txt']);

		% has to be there as it's hardcoded in audapter_ctrl
		S.audapterplay = [];

		S.fontsize = 0.1;
		%controls when next stimulus is displayed
		S.hidemode = 0;
		S.paralleloutmode = 'none'; % no idea what it does (EMA related I think)

		% provide the path to noise sound
		% if strcmp(phase, 'learning')
		% 	baseline = 'baseline';
		% 	stimuli = 'resynthesis';
		% 	stimuliFolder = fullfile(subjectFolder, baseline, stimuli);
		% 	S.audapterplay = fullfile(stimuliFolder);
		% 	S.noise = 'D:\perturbator\data\noise_25sec.wav';
		% 	% see promter_ini_base lines 856 ff
		% end

		% if soundcheck then perturbstart contains a keyboard statement before start of each trial
		if strcmp(phase, 'soundcheck')
			S.usersetfunc = ['perturbini(' quote phaseFolder quote ')'];
			S.userstartfunc = 'perturbstarttest'; 
			S.userstopfunc = 'perturbstop';
		else
			S.usersetfunc = ['perturbini(' quote phaseFolder quote ')'];
			S.userstartfunc = 'perturbstart'; 
			S.userstopfunc = 'perturbstop';
		end

		disp('Use control panel to turn off system sounds if necessary.');
		disp('Hit any key to continue.');
		pause

		prompter_parallel_main(stimFile, logFile, S);
	end
end
