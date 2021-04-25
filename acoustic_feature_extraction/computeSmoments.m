function [CoG, skew, kurt] = computeSmoments(p, f, samplerate)
	
	% compute mean and standard deviation
    CoG = (f * p) ./ (sum(p,1));
    % convert from index to Hz - just additional scaling?
    %CoG = CoG / size(p,1) * samplerate/2;
    tmp = repmat(f, size(p,2),1) - repmat(CoG, size(p,1),1)';
    var_p   = diag (tmp.^2 * p) ./ (sum(p,1)'*size(p,1));
    
    skew = diag (tmp.^3 * p) ./ (var_p.^(3/2) .* sum(p,1)'*size(p,1));
    kurt = diag (tmp.^4 * p) ./ (var_p.^2 .* sum(p,1)'*size(p,1));
end