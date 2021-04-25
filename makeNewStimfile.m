function makeNewStimfile(subjectID, subjectFolder, txtStruct, repetitions, nLPC, f0, language)
    % generate randomized stimulus file from a text struct (containing
    % participant-specific tracking settings)


    if ~exist('language', 'var')
        language = input('Participant''s language (r/g): ','s');
    end


    lengthStruct = length(txtStruct);
    % number of stimuli in the stim base file
    numStim = (lengthStruct-3)/2;
    %number of lines to skip to get to the next stimulus
    skipLines = 2;     

    %a place holder for insertion of repetition number
    repPlaceholder = '_REP#';  
    %determine number of digits to use for repetition number in code
    numRepDig = length(int2str(max(repetitions)));

    %[~, phase] = strtok(txtStruct{3}, ''); for old createStims scripts
    [~, phase] = strtok(txtStruct{3}, '#');
    phase = strtok(phase, '#');
    
    %keyboard
    phase = strtrim(phase);
    stimFile = fullfile(subjectFolder, [phase '_' subjectID '.txt']); 
    stimFileID = fopen(stimFile,'wt');


    % participant's nLPC and f0 settings
    nLPCset = ['#nLPC ' int2str(nLPC) '#f0 ' int2str(f0)]; 


    % write the header of the file
    fprintf(stimFileID, '%s\n', txtStruct{1});
    fprintf(stimFileID, '%s\n', txtStruct{2});
    fprintf(stimFileID, '%s\n', txtStruct{3});

    if strcmp(language, 'r')
        halftime1 = '50% сегмента позади.';
        halftime2 = 'Aufgabenbeschreibung';
    elseif strcmp(language, 'g')
        halftime1 = '50% des Abschnitts vorbei.';
        halftime2 = 'Aufgabenbeschreibung';
    end

    settingsdone = 0;
    repIndex = 1;

    %loop as long not all repetitions written to the file 
    while repetitions > 0
        
        conditionList = 1:numStim;
      
        % message that half of the experiment is over
        % if repIndex == round(repetitions/2)+1
        %     fprintf(stimFileID, '%s\n', halftime1);
        %     fprintf(stimFileID, '%s\n', halftime2);
        % end

        % write every condition reandomized into a file
        while ~isempty(conditionList)

            % select randomly a condition
            randomCondition =  conditionList(randi(numel(conditionList)));
            % collect two lines with stimulus and settings
            tmps1 = txtStruct{skipLines*randomCondition+2};
            tmps2 = txtStruct{skipLines*randomCondition+3}; %settings

            % include the repetition number into settings
            tmps2x = strrep(tmps2, repPlaceholder, ['_' int2str0(repIndex, numRepDig) '#']); 

            fprintf(stimFileID, '%s\n', tmps1); % write first line to the file

            % add formant tracking settings to the audapter settings for the first
            % stimulus
            if ~settingsdone
                ipi = findstr('%',tmps2x);
                tmps2x = [tmps2x(1:(ipi-1)) nLPCset tmps2x(ipi:end)];
                settingsdone = 1;
            end
            
            fprintf(stimFileID, '%s\n', tmps2x); % write second line to the file
                        
            % delete that element from the list of conditions
            conditionList = conditionList(conditionList~=randomCondition); 
            %keyboard
        end

        repIndex = repIndex + 1;
        repetitions = repetitions - 1;

    end

    % write close trial at the end of the stimulus file
    if strcmp(language, 'r')
        fprintf(stimFileID, '%s\n', 'Сегмент закончен.');
    elseif strcmp(language, 'g')
        fprintf(stimFileID, '%s\n', 'Der Abschnitt ist zu Ende.');
    end
    
    fprintf(stimFileID, '%s', 'ENDE');
    fclose(stimFileID);
end