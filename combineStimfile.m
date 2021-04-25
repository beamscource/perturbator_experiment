function combineStimfile(fileA, fileB, subjectFolder, subjectID, phase)
    % combine two txt files
    sbaseA = file2str_u(fileA);
    sbaseA = sbaseA(1:end-2,:); % get rid of end of the segment message
    sbaseB = file2str_u(fileB);
    sbaseB = sbaseB(2:end,:); % get rid of the file starting index
    % join the two stim texts
    txt = strvcat(sbaseA, sbaseB);

    %get phase
    [~, phase] = strtok(sbaseA(3,:), ' ');
    phase = strtrim(phase);

    
    stimFile = fullfile(subjectFolder, [phase '_test_' subjectID '.txt']); 
    stimFileID = fopen(stimFile,'wt',  'UTF-8');

    keyboard
    % write the joined txt to a file
    fwrite(stimFileID, txt(2,:), 'uchar');
    fprintf(stimFileID, '%s', txt(2,:));
    fclose(stimFileID);
end