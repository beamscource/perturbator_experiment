function labelBoundaries(subjectFolder)

	content = dir(subjectFolder);
	folderList = content(find(vertcat(content.isdir)));

    %data = {};

	for folder = 1:length(folderList)
    
    	phase = folderList(folder).name;
    
    	if strcmp(phase, '.') || strcmp(phase, '..') || strcmp(phase, 'soundcheck') || strcmp(phase, 'testing')
        	continue
    	end

    	%data.(sprintf('%s', ['phase' phase])) = extractPhaseSmoments(subjectFolder, phase);
        labelPhaseBoundaries(subjectFolder, phase);
    end

    % save the final struct as a mat file
    %save([subjectFolder '\smoments_' subject '.mat'], 'data')

end