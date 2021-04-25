function extractMeans(subjectFolder)

	content = dir(subjectFolder);
	folderList = content(find(vertcat(content.isdir)));

	for folder = 1:length(folderList)
    
    	phase = folderList(folder).name;
    
    	if strcmp(phase, '.') || strcmp(phase, '..') || strcmp(phase, 'soundcheck') || strcmp(phase, 'testing')
        	continue
    	end

    	[means] = extractPhaseMeans(subjectFolder, phase, 1);
    	%keyboard
        saveFormantsTable(subjectFolder, means)
    end
end