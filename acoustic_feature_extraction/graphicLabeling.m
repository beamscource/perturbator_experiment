function meanFormantsManual = graphicLabeling(vectors, soundName, phase, signalFolder, fileName, timeAxis)

        analysisFile = fileName;
        analysisFolder = strrep(signalFolder, 'signal', 'analysis');
        
        signalFile = strrep(fileName, 'ana', 'sig');
        load(fullfile (signalFolder, signalFile), 'data', 'samplerate');
        signalVec = double(data(:,1));

        fileNr = strtok(fileName, '_');
        %hasbehavior(gco, 'legend', false)

        grey = [0.4,0.4,0.4];

        figure('Name', ['Phase ' phase ' file ' fileNr], 'units', 'normalized', 'outerposition', ...
        [0 0 1 1], 'NumberTitle', 'off');
        iptsetpref('ImshowBorder','tight');
        title(['Response: [' soundName ']'], 'FontSize', 30)
        subplot(2,1,1)
        iptsetpref('ImshowBorder','tight');
%         title(['Response: [' soundName ']'], 'FontSize', 30)
%         ylabel('Frequency (in Hz)','FontSize', 12)
%         xlabel('Time (in s)','FontSize', 12)
%         set(gca,'FontSize', 12)
%         %plot(timeAxis, vectors.rawF1, 'Color', grey);
%         axis tight;
%         ylim([0 3000]);
%         %xlim([100 1600]);
%         hold on
%         plot(timeAxis, vectors.rawF2, 'k');
%         plot(timeAxis, vectors.rangeF1, 'r');
%         plot(timeAxis, vectors.rangeF2, 'r');
%         %plot(timeAxis, vectors.rangeF1Shift, 'g');
%         if length(timeAxis) == length(vectors.rangeF2Shift)
%           plot(timeAxis, vectors.rangeF2Shift, 'g');
%         end
        
        % plot audio signal
%         plot(signalVec, 'k');
%         set(gca, 'YTick', []);
%         set(gca, 'XTick', []);
%         axis tight;
        
        subplot(2,1,2)
        iptsetpref('ImshowBorder','tight');
        % Cai's spectrogramm function
        %show_spectrogram(signalVec, samplerate, 'noFig');
        
        spgrambw(signalVec, samplerate, 'i', 400, 3500, 60);
        hold on
        plot(timeAxis, vectors.rawF1, 'w', 'LineWidth', 2.5);
        plot(timeAxis, vectors.rawF2, 'w', 'LineWidth', 2.5);
        plot(timeAxis, vectors.rawF3, 'w', 'LineWidth', 2.5);
        %soundsc(signalVec(1:end-(round(length(signalVec)/1.5))), samplerate)
       
        %[boundaries] = ginput(2);

        if ~isempty(boundaries)
        
           % define the new boundaries (on the time axis) for the range vector    
           first = boundaries(1);
           last = boundaries(2);
           vowel = [first last];
           vowelDuration = last-first; % in sec

           % write the bondaries to the signal mat file
           save(fullfile (signalFolder, signalFile),'vowel','-append')

           % convert the time boundaries to formant vector data points
           [~, firstIndex] = min(abs(timeAxis-first));
           [~, lastIndex] = min(abs(timeAxis-last));
           vowelIndex = [firstIndex lastIndex];

           % write the index bondaries to the analysis mat file
           save(fullfile (analysisFolder, analysisFile),'vowelIndex','-append')

           % copy raw vector into own struct
           rawVectors.rawF1 = vectors.rawF1;
           rawVectors.rawF2 = vectors.rawF2;
           rawVectors.rawF3 = vectors.rawF3;
           rawVectors.rawF1Shift = vectors.rawF1Shift;
           rawVectors.rawF2Shift = vectors.rawF2Shift;


           % extract vectors from the raw vectors with new boundaries
           fields = fieldnames(rawVectors);
                
           for i = 1:length(fields)
               
              % normalizing and saving the formant vector
              lenVec = length(rawVectors.(fields{i})(firstIndex:lastIndex));
    
              % length with additional 20 data points
              lenAdd = length(rawVectors.(fields{i})(firstIndex-15:lastIndex+15));

              resFactor = round(100*lenAdd/lenVec);

              rawVec = rawVectors.(fields{i})(firstIndex-15:lastIndex+15);
    
              % resample the segment to ~100 + additional samples
              rawVecRes = resample(rawVec, resFactor, length(rawVec));
    
              % compute the number of superfluous samples on each side
              redun = ceil((length(rawVecRes)-100)/2);
    
              % choose the ~100 at the center of the array (trimm 1 additional point at the beginning)
              normVec = rawVecRes(redun+1:length(rawVecRes)-(redun-1));

              % values missing until 100
              miss = 100-length(normVec);
    
              % create array with nan's
              nan = NaN(miss, 1);
    
              % combine the segment with nan
              normVec = [normVec; nan];
    
              % normalize the y-dimension to zero
              %normVec = normVec-normVec(1,1);

              % extract formant vectors
              meanFormantsManual(:,i) = normVec;
           end 
           
           %add vowel duration (in sec) to the matrix
           vowDur = repmat(vowelDuration, length(meanFormantsManual), 1);
           meanFormantsManual = [vowDur meanFormantsManual];

        end

        if ~exist('meanFormantsManual', 'var')
           meanFormantsManual = [];
        end

        close all

        % if strcmp(fileNr, '0051')
        %   keyboard
        % end
end
        