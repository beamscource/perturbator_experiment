function labelPhaseBoundaries(subjectFolder, phase)
    % labeling boundaries and append them to mat-signal files from the passed phase

    phaseFolder = fullfile(subjectFolder, phase);
    
    signal = 'signal';
    signalFolder = fullfile(phaseFolder, signal);

    fileList = dir([signalFolder '\*.mat']);

    % filter specifications for high pass above 300 Hz
    [b, a]= butter(6, 300/(16000/2), 'high');

    % go through each file in the signalFolder folder
    for file = 1:length(fileList)
        
        % set current file name and load the data
        fileName = fileList(file).name;
        fileNameCopy = fileName;
        load(fullfile (signalFolder, fileName), 'data', 'samplerate');
            
        % get stimulus name and trialNum from the file name:
        % sound name is always in the second position trialnumber_soundname_
        loop = 0;
        while 1
            [token, fileNameCopy] = strtok(fileNameCopy, '_');
            loop = loop + 1;
            if loop == 2, break; end
        end
        soundName{file} = token;
        
        signalVec = double(data(:,1));
        signalVec = signalVec(5000:round(length(signalVec)*0.3));

        %% high pass filter the audio
        audioFilter = filtfilt(b, a, signalVec);

        % plot the token with spectrogramm and play it

        figure('Name', [mat2str(phase) mat2str(fileName)], 'units', 'normalized', 'outerposition', ...
            [0 0 1 1], 'NumberTitle', 'off');
        
        subplot(2,1,1), plot(audioFilter, 'k');
        axis tight;
        title(['Response: ' soundName{file}], ...
            'Color', 'black', 'FontSize', 22)
        set(gca,'FontSize', 18)
        
        subplot(2,1,2)
        spgrambw(audioFilter, samplerate, 'j', 400, 8000, 40);
        %axis tight;
        title('Spectrogram', 'FontSize', 22)
        ylabel('Frequency (kHz)','FontSize', 18)
        xlabel('Time (in ms)','FontSize', 18)
        set(gca,'FontSize',18)

        %keyboard
        soundsc(audioFilter, samplerate)

        [boundaries] = ginput(2);
        
        if ~isempty(boundaries)
            first = boundaries(1);
            last = boundaries(2);
            burst = [first last];
            % write the bondaries to the mat file
            save(fullfile (signalFolder, fileName),'burst','-append')
        end

        close all

        % if file == 3
        %       break
        % end
    end
end
