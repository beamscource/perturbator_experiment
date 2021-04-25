function [f1, dy, gy] = plotAllSpectra(subjectFolder)

	% get the inside of the subjectFolder (experimental phases)
    content = dir(subjectFolder);
	folderList = content(find(vertcat(content.isdir)));

    % get subject name
    subjectFolder1 = subjectFolder;
    
    loop = 0;
    while 1
        [token, subjectFolder1] = strtok(subjectFolder1, '\');
        loop = loop + 1;
        if loop == 4, break; end
    end
    subject = token;

    % generate three figures to plot each trial data to
	f1 = figure('Name', 'di(orange) gu (red)');
    hold on
    dy = figure('Name', 'dy');
    hold on
    gy = figure('Name', 'gy');
    hold on

    % loop through experimental phases
	for folder = 1:length(folderList)
    
    	phase = folderList(folder).name;
    
    	if strcmp(phase, '.') || strcmp(phase, '..') || strcmp(phase, 'soundcheck') || strcmp(phase, 'testing')
        	continue
    	end

        % plotting on, save to file off
        extractPhaseSmoments(subjectFolder, phase, 1, 0, f1, dy, gy);
    end

    % extra function to get the means and plot it in two extra figures (one for each syllable)
   	plotAvgSpectra(f1, dy, gy, subject);
end