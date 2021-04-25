function ex_vowelshift(subjectID)

	fclose all;
	close all;

	disp('')
	disp ('Enter return to the console to ''warm-up'' Audapter.')
	disp ('Check participant''s output channel for noises.'  )
	keyboard

	Audapter('start');
	pause(2)
	Audapter('stop');

	disp('')
	disp ('Enter return to the console to start testing the recording quality.')
	disp ('Write down F1 and F2 for each vowel.')
	keyboard

	x1 = datetime('now');
	% 0 = testing phase
	[subjectFolder] = perturbMain(subjectID, 0);

	x2 = datetime('now');
	disp('')
	disp(['Time elapsed: ' char(x2-x1)])
	disp ('Enter return to the console to look at tracking settings for formants.')
	disp('Change formants if needed with following syntax: formants.iF1 = 200')
	keyboard

	% following function creates a struct with default formant values
	%[formants] = formantsMedian(iMeans, ueMeans, uMeans, eMeans, aeMeans, aMeans);
	[formants] = formantsFreq;

	disp ('Enter return to the console to start the baseline phase.')
	keyboard

	x1 = datetime('now');

	% 1 = baseline phase
	[subjectFolder] = perturbMain(subjectID, 1, formants);

	x2 = datetime('now');
	disp('')
	disp(['Time elapsed: ' char(x2-x1)])
	disp('Check the recorded formants. Replace huge outliers.')
	disp ('Replot formants with plotMeans(means)')
	keyboard

	[means] = extractPhaseMeans(subjectFolder, 'baseline');
	plotMeans(means);

	disp ('When ready enter return to the console to make perturbation settings.')
	keyboard
	close all

	[pertSet] = perturbSettings(means);

	disp('')
	disp ('Sanity check the perturbation strings and fomants struct.')
	disp ('When ready enter return to the console to create stimulus files for all phases.')
	keyboard

	createStimfiles(subjectFolder, pertSet, formants);

	disp('')
	disp ('Check whether the order structure was created and stimuli files are inside.')
	% keyboard

	% x1 = datetime('now');

	% % pertubation phase
	% [subjectFolder] = perturbMain(subjectID, 7);

	% x2 = datetime('now');

	% disp('')
	% disp(['Time elapsed: ' char(x2-x1)])
	% disp ('Enter return to the console to start the last phase.')
	keyboard

	x1 = datetime('now');

	% double perturbation phase
	[subjectFolder] = perturbMain(subjectID, 8);

	x2 = datetime('now');

	disp('')
	disp(['Time elapsed: ' char(x2-x1)])
	disp ('Experiment is over now. Be nice to the participant!')

end
