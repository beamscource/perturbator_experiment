function replayConvert(subjectFolder, phase)
% replay mat-files which were recorded with Audapter
% original and perturbed signals are replayed one after another
% perturbed signal is saved as wav-files
% June 2016

phaseFolder = fullfile(subjectFolder, phase);

audio = 'wav';
wavFolder = fullfile(subjectFolder, audio);

sigFolder = 'signal';
fileList = dir(fullfile(phaseFolder, [sigFolder '\*.mat']));

for file = 1:length(fileList)
	load(fullfile(phaseFolder, sigFolder, fileList(file).name));

	%soundsc(data(:,1), samplerate)
    %disp(fileList(file).name)
	soundsc(data(:,2), samplerate); % perturbed signal
	pause
 	%wavFile = [strtok(fullfile(wavFolder, phase, fileList(file).name), '.') '.wav'];
 	%keyboard
 	%audiowrite(wavFile, data(:,1), samplerate);
end