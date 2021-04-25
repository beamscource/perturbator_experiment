function ex_ema_frication(subjectID)
	% experiment with German participants perturbing fricatives

	fclose all;
	close all;

	Audapter('start');
	pause(1)
	Audapter('stop');

	if ~exist('subjectID', 'var')
		subjectID = input('Participant''s ID: ','s');
	end

	disp('')
	disp ('Enter return to the console to start SOUNDCHECK.')
	disp ('Adjust microphone for OST tracking.')
	keyboard

	x1 = datetime('now');
	
	%soundcheck phase when subjectID is new
	[subjectFolder, gender] = perturbatorEMA(subjectID, []);

	x2 = datetime('now');
	disp('')
	disp(['Time elapsed: ' char(x2-x1)])
	disp ('Enter return to the console to start the experiment.')
	keyboard

	pertSet = perturbSettingsEMAFRIC;

	% create stim files for all phases
	
	createStimsEMAFRIC(subjectFolder, gender, {}, {}, 'familiarization');
	createStimsEMAFRIC(subjectFolder, gender, {}, {}, 'baseline');
	createStimsEMAFRIC(subjectFolder, gender, {}, pertSet);
	createStimsEMAFRIC(subjectFolder, gender, {}, {}, 'post');

	x1 = datetime('now');

	% perturbator going to loop through all stim files created
	perturbatorEMA(subjectID, gender);

	x2 = datetime('now');

	disp('')
	disp(['Time elapsed: ' char(x2-x1)])
	disp ('Experiment is over now. Be nice to the participant!')
end
