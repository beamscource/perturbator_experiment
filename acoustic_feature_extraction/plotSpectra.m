function plotSpectra(burstSignal, samplerate, token, phase, f1, dy, gy)

	cellObj = {burstSignal, samplerate};
	L = (length(burstSignal)/samplerate)/2;
    [p, f]=ComputeAOS(cellObj, L);

    m = mean(p, 2);
    
    switch token
    case 'di'
    	figure(dy)	
    	plot(f, (m - m(1)), 'r')
    case 'gu'
    	figure(gy)
    	plot(f, (m - m(1)), 'r')
    case 'dy'
    	figure(dy)
    	switch phase
    	case 'baseline'
    		plot(f, (m - m(1)), 'k')
    	case '220'
    		plot(f, (m - m(1)), 'b')
    	case '370'
    		plot(f, (m - m(1)), 'g')
    	case '520'
    		plot(f, (m - m(1)), 'm')
    	end
    	%keyboard
    case 'gy'
    	figure(gy)
    	switch phase
    	case 'baseline'
    		plot(f, (m - m(1)), 'k')
    	case '220'
    		plot(f, (m - m(1)), 'b')
    	case '370'
    		plot(f, (m - m(1)), 'g')
    	case '520'
    		plot(f, (m - m(1)), 'm')
    	end
    end
end