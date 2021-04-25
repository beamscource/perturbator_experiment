function ex_frication(subjectID)
	% experiment with Russian participants perturbing fricatives

	fclose all;
	close all;

	Audapter('start');
	pause(1)
	Audapter('stop');

	if ~exist('subjectID', 'var')
		subjectID = input('Participant''s ID: ','s');
	end

	if ~exist('vers', 'var')
		vers = input('Experiment version (a/b/c (!)): ','s');
	end

	disp('')
	disp ('Enter return to the console to start SOUNDCHECK.')
	disp ('Adjust microphone for OST tracking.')
	keyboard

	x1 = datetime('now');
	%soundcheck phase when subjectID is new
	[subjectFolder, gender] = perturbatorFRIC(subjectID, [], vers);

	x2 = datetime('now');
	disp('')
	disp(['Time elapsed: ' char(x2-x1)])
	disp ('Enter return to the console to start the experiment.')
	keyboard

	switch vers
		case 'a'
			pertSet = perturbSettingsFRICA;
		case 'b'
			pertSet = perturbSettingsFRICA;
		case 'c'
			pertSet = perturbSettingsFRICA;
	end

	% create stim files for all phases
	switch vers
		case 'a' 
			createStimsFRICA(subjectFolder, gender, {}, {}, 'baseline');
			createStimsFRICA(subjectFolder, gender, {}, pertSet);
		case 'b' 
			createStimsFRICB(subjectFolder, gender, {}, {}, 'baseline');
			createStimsFRICB(subjectFolder, gender, {}, pertSet);
			createStimsFRICB(subjectFolder, gender, {}, pertSet, 'crosseffects');
		case 'c'
			createStimsFRICC(subjectFolder, gender, {}, {}, 'baseline');
			createStimsFRICC(subjectFolder, gender, {}, pertSet);
			createStimsFRICC(subjectFolder, gender, {}, pertSet, 'crosseffects');
	end

	x1 = datetime('now');

	% perturbator going to loop through all stim files created
	perturbatorFRIC(subjectID, gender, vers);

	x2 = datetime('now');

	disp('')
	disp(['Time elapsed: ' char(x2-x1)])
	disp ('Experiment is over now. Be nice to the participant!')
end
