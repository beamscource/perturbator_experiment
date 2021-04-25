function pertSet = perturbSettingsFRICA;

	% phases
    phases = {'2shift', '2test', '3shift', '3test', '4shift', '4test'};

   	for i = 1:length(phases)
       	pertSet.(['pertSettings_' char(phases(i)) '_d']) = '#pcf D:\perturbator\fricationsound\ost_rules\fricative_up.pcf%OST_pitchshift_up'; 
       	pertSet.(['pertSettings_' char(phases(i)) '_up']) = '#pcf D:\perturbator\fricationsound\ost_rules\fricative_down.pcf%OST_pitchshift_down';
   	end
end