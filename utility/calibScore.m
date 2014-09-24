function [probscore,probup,probdn] = calibScore( SVMscore, parmhat, parmci, minscore )
%CALIBSCORE Return the calbirated score
%   by Ender, xinleic@cs.cmu.edu

SVMscore = -SVMscore - minscore + 1;

if nargout > 1
    [probscore,probup,probdn] = wblcdf(SVMscore,parmhat(1),parmhat(2),parmci);
else
    probscore = wblcdf(SVMscore,parmhat(1),parmhat(2));
end

end