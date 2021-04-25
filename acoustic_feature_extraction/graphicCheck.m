function meanFormantsManual = graphicCheck(vectors, soundName)
        
        vectors.rangeF1(vectors.rangeF1 == 0) = NaN;
        vectors.rangeF2(vectors.rangeF2 == 0) = NaN;
        vectors.rangeF2Shift(vectors.rangeF2Shift == 0) = NaN;

        %hasbehavior(gco, 'legend', false)

        grey = [0.4,0.4,0.4];

        figure('Name', 'Fomants (F1-F2)', 'units', 'normalized', 'outerposition', ...
        [0 0 1 1], 'NumberTitle', 'off');
        axis tight;
        ylim([0 3000]);
        xlim([100 1600]);
        title(['Response: [' soundName ']'], 'FontSize', 30)
        ylabel('Frequency (in Hz)','FontSize', 28)
        xlabel('Data points','FontSize', 28)
        set(gca,'FontSize', 26)
        hold on
        plot(vectors.rawF1, 'Color', grey);
        plot(vectors.rawF2, 'k');
        plot(vectors.rangeF1, 'r');
        plot(vectors.rangeF2, 'r');
        %plot(vectors.rangeF1Shift, 'g');
        plot(vectors.rangeF2Shift, 'g');

        [boundaries] = ginput(2);

        if ~isempty(boundaries)
        
           % define the new boundaries for the range vector    
           first = round(boundaries(1));
           last = round(boundaries(2));

           % copy raw vector into own struct
           rawVectors.rawF1 = vectors.rawF1;
           rawVectors.rawF2 = vectors.rawF2;
           rawVectors.rawF3 = vectors.rawF3;
           rawVectors.rawF1Shift = vectors.rawF1Shift;
           rawVectors.rawF2Shift = vectors.rawF2Shift;

           % extract the medians from the raw vectors with new boundaries
           fields = fieldnames(rawVectors);
                
           for i = 1:length(fields)
               meanFormantsManual(i) = round(median(rawVectors.(fields{i})(first:last)));
           end 
        end

        if ~exist('meanFormantsManual', 'var')
           meanFormantsManual = [];
        end
        
        close all
end
        