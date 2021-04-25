function formants = formantsRus(gender)

    % implement fn2 = frequency of the second formant
    % implement fn1 = frequency of the first formant

    if ~exist('gender', 'var')
        gender = input('Participant''s gender? (m/f): ','s');
    end

    if strcmp(gender, 'm')
        iF1 = 300;
        iF2 = 2200;
        
        yF1 = 300;
        yF2 = 1500;
        
        uF1 = 400;
        uF2 = 700;
        
        eF1 = 400;
        eF2 = 2000;
        
        aeF1 = 500; 
        aeF2 = 1500;
        
        aF1 = 800;
        aF2 = 1400;
    else 
        iF1 = 350;
        iF2 = 2500;
        
        yF1 = 350;
        yF2 = 1800;
        
        uF1 = 450;
        uF2 = 900;
        
        eF1 = 450;
        eF2 = 2400;
        
        aeF1 = 600; 
        aeF2 = 1600;
        
        aF1 = 900;
        aF2 = 1600;
    end

    % combine a srtuct of the formant tracking settings
    formants = struct('iF1', iF1, 'iF2', iF2, 'yF1', yF1, 'yF2', yF2, ...
        'uF1', uF1, 'uF2', uF2, 'eF1', eF1, 'eF2', eF2, 'aeF1', aeF1, 'aeF2', aeF2, 'aF1', aF1, 'aF2', aF2);

    disp(formants)
end