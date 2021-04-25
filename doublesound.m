mainDir = 'D:\perturbator\doublesound\data';
content = dir(mainDir);
content = content(5:end);

keyboard

for i = 1:length(content)

	extractMeans(fullfile(mainDir, content(i).name))

end