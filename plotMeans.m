function plotMeans(means, perturbed)
% plot the formants
% if the perturbed flag is set to 1, perturbed signal is plotted

perturbed = 0;

figure('Name', [sprintf('%s', means.phase) ' vowel map']); hold on
set(gca,'YDir','reverse')
set(gca,'XDir','reverse')
set(gca,'XAxisLocation','top','YAxisLocation','right')
title([sprintf('%s', means.phase) ' vowel map'])
xlabel('F2 in Hz')
ylabel('F1 in Hz')

% remove the phase field before plotting
if isfield(means, 'phase')
	means = rmfield(means, 'phase');
end

% get field names
fields = fieldnames(means);

% need more colors in the list
colr = {'b', 'g', 'm', 'r', 'k', 'c', 'y'};

% iterate through the fields
for i = 1:length(fields)
	if perturbed
		plot(means.(fields{i})(:,6), means.(fields{i})(:,5), ['o' colr{i}])
	else
		plot(means.(fields{i})(:,3), means.(fields{i})(:,2), ['o' colr{i}])
	end
end

legend(fields, 'Location', 'southeastoutside')
