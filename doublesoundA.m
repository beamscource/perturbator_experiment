function doublesoundA(subjectID)
	% experiment with Russian participants
	% extreme perturbation
	% increasing from 220 Hz to 350 Hz to 500 Hz
	
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
	[subjectFolder, gender] = perturbator(subjectID);

	x2 = datetime('now');
	disp('')
	disp(['Time elapsed: ' char(x2-x1)])
	disp ('Enter return to the console to look at the formants.')
	keyboard

	% following function creates a struct with default formant values
	formants = formantsRus(gender);

	% create stim files for baseline
	createStimsDS(subjectFolder, gender, formants, {}, 'baseline');

	disp('Change formants for TRACKING with following syntax: formants.iF1 = 200')
	disp ('Enter return to the console to start the BASELINE phase.')
	keyboard

	x1 = datetime('now');

	% baseline phase
	perturbator(subjectID, gender);

	x2 = datetime('now');
	disp('')
	disp(['Time elapsed: ' char(x2-x1)])
	disp('Check the recorded formants.')
	keyboard

	[means] = extractPhaseMeans(subjectFolder, 'baseline', 0);
	plotMeans(means);

	pertSet = perturbSettingsDS;

	disp('')
	disp ('Sanity check the PERTURBATION strings and FORMANTS struct.')
	disp ('When ready enter return to the console to create stimulus files for all phases.')
	keyboard

	createStimsDS(subjectFolder, gender, formants, pertSet)

	disp('')
	disp ('Check whether the order structure was created and stimuli files are inside.')
	disp ('Enter return to the console to start the remaining phases (3*60 trials).')
	keyboard

	x1 = datetime('now');

	% perturbator going to loo through all stim files created
	perturbator(subjectID, gender);

	x2 = datetime('now');

	disp('')
	disp(['Time elapsed: ' char(x2-x1)])
	disp ('Experiment is over now. Be nice to the participant!')
end
