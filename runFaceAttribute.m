function runFaceAttribute

% Directory setup
p = mfilename('fullpath');
[p,~,~] = fileparts(p);

% Find Expression
if ismac
    [~,d] = system(['find ' fileparts(p) ' -name Expression']); % Assuming Expression and Dominance are located in the same directory
elseif ispc
    [~,d] = system('dir /b/ad *Expression*');
    d = [fileparts(p) filesep d];
else
    error('runFaceAttribute: Unsupported OS.');
end

addpath(d); % Make sure added to path

% Property additions
block = {'m2_sub','m2_dom','m1_sub','m1_dom','f3_sub','f3_dom','f1_sub','f1_dom'};
imgsize = [411 276 3];
rescale = 0;
path.base = p;
audio_on = 0;
type = 'FaceAttribute';
pracadd = 0;
timelim = [3 .75 2]; % Response duration (1), ITI (2), Display duration (3)
fix = 1;

runExpression(block,imgsize,rescale,path,audio_on,type,pracadd,timelim,fix);

end