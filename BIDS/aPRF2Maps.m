function [] = aPRF2Maps(bidsfolder, subject, session, desc)
% Convert the output of analyze PRF, i.e. results struct, to an MGZ 
%
%
% INPUTS
%   bidsfolder  : path to BIDS project
%   subject     : BIDS subject name
%   session     : BIDS session name
%   desc        : type of model [default = ''];
%
% OUTPUTS
%
% Example
%  bidsfolder =  '/Volumes/server/Projects/SampleData/BIDS/'
%  subject    =  'wlsubj042'
%  session    = '01';
%  desc       = 'coarse';
%  aPRF2Maps(bidsfolder, subject, session, desc)

% Path to analyze PRF results
pth = fullfile(bidsfolder, 'derivatives', 'analyzePRF', desc, ['sub-' subject], ['ses-' session]);

% JSON file with input arguments to analyzePRF
opts = loadjson(fullfile(pth, sprintf('sub-%s_ses-%s_%s_inputVar.json', subject, session, desc)));
pix2deg = @(x) x * opts.stimwidthdeg / opts.stimwidthpix;

% AnalyzePRF results file
load(fullfile(pth, sprintf('sub-%s_ses-%s_%s_results.mat', subject, session, desc)), 'results');

% Freesurfer directory
fspth = fullfile(bidsfolder, 'derivatives', 'freesurfer', ['sub-' subject]);

lcurv = read_curv(fullfile(fspth, 'surf', 'lh.curv'));
rcurv = read_curv(fullfile(fspth, 'surf', 'rh.curv'));
assert(isequal(numel(lcurv) + numel(rcurv), numel(results.ang)), ...
    'The number of vertices in the aprf results and the l&r curv files do not match;');

mgz = MRIread(fullfile(fspth, 'mri', 'orig.mgz'));

% what are the files expected by bayesian retinotopy?
% left and right theta (in radians), eccen, size, r2
leftidx  = 1:numel(lcurv);
rightidx = (1:numel(rcurv))+numel(lcurv);

% polar angle in radians
mgz.vol = deg2rad(results.ang(leftidx));
MRIwrite(mgz, fullfile(pth, 'lh.angle.mgz'));
mgz.vol = deg2rad(results.ang(rightidx));
MRIwrite(mgz, fullfile(pth, 'rh.angle.mgz'));

% eccentricity (convert from pix 2 deg)
mgz.vol = pix2deg(results.ecc(leftidx));
MRIwrite(mgz, fullfile(pth, 'lh.eccen.mgz'));
mgz.vol = pix2deg(results.ecc(rightidx));
MRIwrite(mgz, fullfile(pth, 'rh.eccen.mgz'));

% pRFsize (convert from pix 2 deg)
mgz.vol = pix2deg(results.rfsize(leftidx));
MRIwrite(mgz, fullfile(pth, 'lh.sigma.mgz'));
mgz.vol = pix2deg(results.rfsize(rightidx));
MRIwrite(mgz, fullfile(pth, 'rh.sigma.mgz'));

% r2 (convert from percentage to fraction)
mgz.vol = results.R2(leftidx)/100;
MRIwrite(mgz, fullfile(pth, 'lh.vexpl.mgz'));
mgz.vol = results.R2(rightidx)/100; 
MRIwrite(mgz, fullfile(pth, 'rh.vexpl.mgz'));

% gain (in percent signal change)
mgz.vol = results.gain(leftidx);
MRIwrite(mgz, fullfile(pth, 'lh.gain.mgz'));
mgz.vol = results.gain(rightidx);
MRIwrite(mgz, fullfile(pth, 'rh.gain.mgz'));

% exponent
mgz.vol = results.expt(leftidx);
MRIwrite(mgz, fullfile(pth, 'lh.expon.mgz'));
mgz.vol = results.expt(rightidx);
MRIwrite(mgz, fullfile(pth, 'rh.expon.mgz'));

end


