function ex_dsound(subjectID)
	% experiment with Russian participants
	% extreme perturbation
	% increasing from 220 Hz to 350 Hz to 500 Hz
	
	fclose all;
	close all;

	%warm-up Audapter
	Audapter('start');
	pause(1)
	Audapter('stop');

	if ~exist('subjectID', 'var')
		subjectID = input('Participant''s ID: ','s');
	end

	if ~exist('vers', 'var')
		vers = input('Experiment version (a/b/c (neutral)): ','s');
	end

	disp('')
	disp ('Enter return to the console to start SOUNDCHECK.')
	disp ('Write down F1 and F2 for each vowel.')
	keyboard

	x1 = datetime('now');
	% soundcheck phase when subjectID is new
	[subjectFolder, gender] = perturbatorDS(subjectID, [], vers);

	x2 = datetime('now');
	disp('')
	disp(['Time elapsed: ' char(x2-x1)])
	disp ('Enter return to the console to look at the formants.')
	keyboard

	% following function creates a struct with default formant values
	formants = formantsRus(gender);

	% create stim files for baseline
	switch vers
		case 'a'
			createStimsDS(subjectFolder, gender, formants, {}, 'baseline')
		case 'b'
			createStimsDS(subjectFolder, gender, formants, {}, 'baseline')
		case 'c'
			createStimsDSneutral(subjectFolder, gender, formants, {}, 'baseline')
	end

	disp('Change formants for TRACKING with following syntax: formants.iF1 = 200')
	disp ('Enter return to the console to start the BASELINE phase.')
	keyboard

	x1 = datetime('now');

	% baseline phase
	perturbatorDS(subjectID, gender, vers);

	x2 = datetime('now');
	disp('')
	disp(['Time elapsed: ' char(x2-x1)])
	disp('Check the recorded formants.')
	keyboard

	[means] = extractPhaseMeans(subjectFolder, 'baseline', 0);
	plotMeans(means);

	switch vers
		case 'a'
			pertSet = perturbSettingsDS;
		case 'b'
			pertSet = perturbSettingsDSB;
		case 'c'
			pertSet = perturbSettingsDS;
	end

	disp('')
	disp ('Sanity check the PERTURBATION strings and FORMANTS struct.')
	disp ('When ready enter return to the console to create stimulus files for all phases.')
	keyboard

	switch vers
		case 'a'
			createStimsDS(subjectFolder, gender, formants, pertSet)
		case 'b'
			createStimsDS(subjectFolder, gender, formants, pertSet)
		case 'c'
			createStimsDSneutral(subjectFolder, gender, formants, pertSet)
	end

	disp('')
	disp ('Check whether the order structure was created and stimuli files are inside.')
	disp ('Enter return to the console to start the remaining phases (3*60 trials).')
	keyboard

	x1 = datetime('now');

	% perturbatorDS going to loop through all stim files created
	perturbatorDS(subjectID, gender, vers);

	x2 = datetime('now');

	disp('')
	disp(['Time elapsed: ' char(x2-x1)])
	disp ('Experiment is over now. Be nice to the participant!')
end
