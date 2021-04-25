function subjectID = newsound(subjectID)

fclose all;
close all;

disp('')
disp ('Enter return to the console to ''warm-up'' Audapter.')
disp ('Check participant''s output channel for noises.'  )
keyboard

audapterDemo_online('playWave');
audapterDemo_online('persistentPitchShift');
close all

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
x1 = datetime('now');

[means] = extractMeans(subjectFolder);
plotMeans(means);

disp ('When ready enter return to the console to make perturbation settings.')
keyboard
close all

[pertSet] = perturbSettings(means)

disp('')
disp ('Sanity check the perturbation strings and fomants struct.')
disp ('When ready enter return to the console to create stimulus files for all phases.')
keyboard

createStimfiles(subjectFolder, pertSet, formants);

disp('')
disp ('Check whether the order structure was created and stimuli files are inside.')
disp ('When ready enter return to the console to synthesize vowels for the learning phase.')
disp ('Watch out for the ''bad'' ones.')
keyboard
synthesize(pertSet); % rewrite

disp('')
disp ('Check whether the synthesized files are inside subjectFolder/baseline/resynthesis.')
disp ('Delete the ''bad'' ones.')
disp ('Enter return to the console to replay the files and to convert them to wav.')
disp ('Perform last sanity check with Praat.')
keyboard

replayConvert(subjectFolder);

x2 = datetime('now');

disp('')
disp(['Time elapsed: ' char(x2-x1)])
disp ('All manipulations successefully performed.')
disp ('Ask the participant to insert the bite block and enter return.')
keyboard

x1 = datetime('now');

% 2 = tryout phase
[subjectFolder] = perturbMain(subjectID, 2);

x2 = datetime('now');

disp('')
disp(['Time elapsed: ' char(x2-x1)])
disp ('Enter return to the console to start the last phase.')
disp ('participant''s feedback is covered with noise!')
keyboard

x1 = datetime('now');

% 3 = learning (test) phase
[subjectFolder] = perturbMain(subjectID, 3);

x2 = datetime('now');

disp('')
disp(['Time elapsed: ' char(x2-x1)])
disp ('Ask the participant to remove the bite block.')
disp ('Experiment is over now. Be nice to the participant!')

