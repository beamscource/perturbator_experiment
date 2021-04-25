function ex_learnsound(subjectID)
	% experiment for German participants
	% learning a new sound between /y/ and /u/
	
	fclose all;
	close all;

	disp('')
	disp ('Enter return to the console to ''warm-up'' Audapter.')
	disp ('Check participant''s output channel for noises.'  )
	keyboard

	Audapter('start');
	pause(1)
	Audapter('stop');

	disp('')
	disp ('Enter return to the console to start SOUNDCHECK.')
	disp ('Write down F1 and F2 for each vowel.')
	keyboard

	x1 = datetime('now');
	% soundcheck phase when subjectID is new
	[subjectFolder, gender] = perturbatorLS(subjectID);

	x2 = datetime('now');
	disp('')
	disp(['Time elapsed: ' char(x2-x1)])
	disp ('Enter return to the console to look at the formants.')
	keyboard

	% following function creates a struct with default formant values
	formants = formantsGer(gender);

	% create stim files for baseline
	createStimsLS(subjectFolder, gender, formants, {}, 'baseline');

	disp('Change formants for TRACKING with following syntax: formants.iF1 = 200')
	disp ('Enter return to the console to start the BASELINE phase.')
	keyboard

	x1 = datetime('now');

	% baseline phase
	perturbatorLS(subjectID, gender);

	x2 = datetime('now');
	disp('')
	disp(['Time elapsed: ' char(x2-x1)])
	disp('Check the recorded formants.')
	keyboard

	%visual inspection of the means
	[means] = extractPhaseMeans(subjectFolder, 'baseline', 0);
	plotMeans(means);

	% choose which direction bias should go
	if ~exist('bias', 'var')
    	bias = input('Bias towards which phonetic category? (y/u): ','s');
	end

	pertSet = perturbSettingsLS(means, bias);

	disp('')
	disp ('Sanity check the PERTURBATION strings and FORMANTS struct.')
	disp ('When ready enter return to the console to create stimulus files for all phases.')
	keyboard

	createStimsLS(subjectFolder, gender, formants, pertSet)

	disp('')
	disp ('Check whether the order structure was created and stimuli files are inside.')
	disp ('Enter return to the console to start the remaining phases (2*48 + 12*36 trials).')
	keyboard

	x1 = datetime('now');

	% perturbator going to loo through all stim files created
	perturbatorLS(subjectID, gender);

	x2 = datetime('now');

	disp('')
	disp(['Time elapsed: ' char(x2-x1)])
	disp ('Experiment is over now. Be nice to the participant!')
end