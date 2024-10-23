function [PPTT,labels,units] = POLPREDgetAPI_1_2(params,fun)
% POLPREDgetAPI - Get tide data from the POLPRED API
% [PPTT,labels,units] = POLPREDgetAPI(params,fun)
%
% input:
% fun       - 'TS' time series,'SA' spatial area, 'PL' port list, or 
%               'PTS' port time series
%
% params.key   - key
% for time series:
% params.lat   - latitude, decimal degrees
% params.lon   - longitude, decimal degrees
% params.sTime - start time, datetime
% params.eTime - end time, datetime
% params.int   - interval 5, 6, 10, 12, 15, 20, 30 or 60 minutes
%
%for port time series, as for time series plus
% params.port_name - port name from call to 'PL' (string)
%
% for spatial area:
% params.latN   - North boundary latitude, decimal degrees
% params.latS   - South boundary latitude, decimal degrees
% params.lonW   - West boundary longitude, decimal degrees
% params.lonE   - East boundary longitude, decimal degrees
% params.sTime  - time, datetime
%
% Optional:
% params.licenceN - number of licence to use (in order i.e. 1, 2 3 etc.)
% (this doesn't work)
%
% output:
% PPTT         - table of data
% labels       - data headers 
% units        - varible units
%
% user defined functions called: none
%

%{
POLPREDgetAPI_dev.m - 1.2 (Matlab 2023a)

A function to get tide data from the POLPRED API. 

POLPRED predictions are always to the “undisturbed sea surface” which is
approximately Mean Sea Level.

** Doesn't check for maximum number of points allowed by API (1280) or
use multiple licences in a call
https://apps.noc-innovations.co.uk/docs/polpred-api/_contents/available-functions.html#compute-spatial

ts.data.headers
    dt: 'Date/Time'
     z: 'Height'
     u: 'EW Component'
     v: 'NS Component'
     m: 'Current Speed'
     d: 'Direction'

ts.data.units
    dt: 'utc'
     z: 'm'
     u: 'm/s'
     v: 'm/s'
     m: 'm/s'
     d: 'deg'

by D. Lichtman, 2023/03/15

References:
https://apps.noc-innovations.co.uk/docs/polpred-api/index.html

update history:
2023/04/03 DL: Get spatial data. Use datetime as input instead of date 
                number.
2023/03/31 DL: Get port list and port time series
%}


%% API details
api = 'https://apps.noc-innovations.co.uk/api/polpred-api/latest/';

if sum(strcmp(fieldnames(params),'key')) % exist field
    key = params.key; 
else
    key = 'U2uf2HSEBrDXV2jl'; % demo key
end

%{
% define which licence to use if there are multiple licences --------------
if sum(strcmp(fieldnames(params),'licenceN')) % exist field
    idN = params.licenceN;
else
    idN = 1; % use the first licence
end
%}

%% settings
switch fun
case 'TS'
lat = num2str(round(params.lat,3));  % Decimal degrees
lon = num2str(round(params.lon,3));  % Decimal degrees

sTime = char(params.sTime,'yyyy-MM-dd HH:mm:ss');%datestr(params.sTime,31);
sTime = [strrep(sTime,' ','T'),'Z']; % start -String (UTC ISO8601 standard)

eTime = char(params.eTime,'yyyy-MM-dd HH:mm:ss');%datestr(params.eTime,31);
eTime = [strrep(eTime,' ','T'),'Z']; % end - String (UTC ISO8601 standard)

int = num2str(params.int); % interval - 5, 6, 10, 12, 15, 20, 30 or 60 mins

case 'SA'
latN = num2str(round(params.latN,3));  % Decimal degrees
latS = num2str(round(params.latS,3));  % Decimal degrees
lonW = num2str(round(params.lonW,3));  % Decimal degrees
lonE = num2str(round(params.lonE,3));  % Decimal degrees

sTime = char(params.sTime,'yyyy-MM-dd HH:mm:ss');%datestr(params.sTime,31);
sTime = [strrep(sTime,' ','T'),'Z']; % start -String (UTC ISO8601 standard)

otherwise
        error('POLPREDgetAPI: fun must be ''TS'', ''SA'', ''PL'' or ''PTS')
end

%% Check licences or get port list
if ~strcmp(fun,'PL')
    url = [api,'get-licences?key=',key];
    
    try
        licenceDetails = webread(url);
    catch
        error('POLPREDgetAPI: API not responding')
    end
    
    if licenceDetails.data.totalLicences < 1
        error('POLPREDgetAPI: no licence') 
    end
    
    disp(licenceDetails.data.licences(1).details.model.name)

else
    url = [api,'get-port-list'];
    try
        port_list = webread(url);
        % dimension timetable 
        nData = size([port_list.data.items.lng],2);
        PPTT = table('Size',[nData,3],'VariableTypes', ...
            {'cellstr','double','double'}, ...
            'VariableNames',{'Name','Latitude','Longitude'});
        PPTT.Name = {port_list.data.items.name}';
        PPTT.Latitude = [port_list.data.items.lat]';
        PPTT.Longitude = [port_list.data.items.lng]';
        labels = {'Name','Latitude','Longitude'};
        units = {'None','Degrees','Degrees'};

    catch
        error('POLPREDgetAPI: API not responding')
    end
end

%% get data
switch fun

% time series -------------------------------------------------------------
case 'TS'
url = [api,'compute-time-series?key=',key,'&lat=',lat,'&lng=',lon, ...
    '&dt_start=',sTime,'&dt_end=',eTime,'&interval=',int];

try
    ts = webread(url);
catch
    error('POLPREDgetAPI: API not responding')
end

nData = ts.data.totalItems;
fields = fieldnames(ts.data.headers);
nVar = size(fields,1);

%ts.data.headers.(fields{VarCt})
%ts.data.items.(fields{2})

% datetime
rowTimes = ...
  datetime({ts.data.items.(fields{1})}','InputFormat', ...
                'yyyy-MM-dd''T''HH:mm:ssZ','TimeZone','UTC');

% variable types
vTypes = mat2cell(repmat('double',nVar-1,1),ones(1,nVar-1))'; 

% dimension timetable 
PPTT = timetable('Size',[nData,nVar-1],'VariableTypes',vTypes, ...
    'RowTimes',rowTimes,'VariableNames',fields(2:nVar));

labels{nVar} = []; units{nVar} = [];  % dimension labels & units arrays
labels{1} = ts.data.headers.(fields{1});
units{1} = ts.data.units.(fields{1});

% put data in the timetable and the headers in the labels array.
for VarCt = 2:nVar
    PPTT.(fields{VarCt}) = [ts.data.items.(fields{VarCt})]';
    labels{VarCt} = ts.data.headers.(fields{VarCt});
    units{VarCt} = ts.data.units.(fields{VarCt});
end

% Port time series data ---------------------------------------------------
case 'PTS'
params.port_name = strrep(params.port_name,' ','%20');

url = [api,'compute-port?key=',key,'&port_name=',params.port_name, ...
    '&dt_start=',sTime,'&dt_end=',eTime,'&interval=',int];

try
    ts = webread(url);
catch
    error('POLPREDgetAPI: API not responding')
end

nData = ts.data.totalItems;
fields = fieldnames(ts.data.headers);
nVar = size(fields,1);

% datetime
rowTimes = ...
  datetime({ts.data.items.(fields{1})}','InputFormat', ...
                'yyyy-MM-dd''T''HH:mm:ssZ','TimeZone','UTC');

% variable types
vTypes = mat2cell(repmat('double',nVar-1,1),ones(1,nVar-1))'; 

% dimension timetable 
PPTT = timetable('Size',[nData,nVar-1],'VariableTypes',vTypes, ...
    'RowTimes',rowTimes,'VariableNames',fields(2:nVar));

labels{nVar} = []; units{nVar} = [];  % dimension labels & units arrays
labels{1} = ts.data.headers.(fields{1});
units{1} = ts.data.units.(fields{1});

% put data in the timetable and the headers in the labels array.
for VarCt = 2:nVar
    PPTT.(fields{VarCt}) = [ts.data.items.(fields{VarCt})]';
    labels{VarCt} = ts.data.headers.(fields{VarCt});
    units{VarCt} = ts.data.units.(fields{VarCt});
end

% Spatial area data -------------------------------------------------------
case 'SA'

url = [api,'compute-spatial?key=',key,'&lat_n=',latN,'&lat_s=',latS, ...
    '&lng_w=',lonW,'&lng_e=',lonE,'&dt=',sTime];
% '&licence_ids=',num2str(licenceDetails.id(idN)) % doesn't work
try
    ts = webread(url);
catch
    error('POLPREDgetAPI: API not responding')
end

nData = ts.data.items.totalPoints;
fields = fieldnames(ts.data.headers);
nVar = size(fields,1);

rowTimes = ...
  datetime(repmat({ts.data.dt},1,nData)','InputFormat', ...
                'yyyy-MM-dd''T''HH:mm:ssZ','TimeZone','UTC');

% variable types
vTypes = mat2cell(repmat('double',nVar,1),ones(1,nVar))'; 

% dimension timetable 
PPTT = timetable('Size',[nData,nVar],'VariableTypes',vTypes, ...
                'RowTimes',rowTimes,'VariableNames',fields);
labels{nVar} = []; units{nVar} = [];  % dimension labels & units arrays

PPTT.model{1} = ts.data.items.model.name;
PPTT.model{2} = ts.data.items.model.code;
PPTT.model{3} = ['Latitude step: ',num2str(ts.data.items.modelStepLat)];
PPTT.model{4} = ['Longitude step: ',num2str(ts.data.items.modelStepLng)];
PPTT.model{5} = ['Resolution: ',num2str(ts.data.items.resolution)];
PPTT.model{6} = ['Total points: ',num2str(ts.data.items.totalPoints)];
PPTT.model{7} = ts.params.lat_n;
PPTT.model{8} = ts.params.lat_s;
PPTT.model{9} = ts.params.lng_w;
PPTT.model{10} = ts.params.lng_e;
PPTT.model{11} = ts.params.dt;

% put data in the timetable and the headers in the labels array.
for VarCt = 1:nVar
    PPTT.(fields{VarCt}) = [ts.data.items.points.(fields{VarCt})]';
    labels{VarCt} = ts.data.headers.(fields{VarCt});
    units{VarCt} = ts.data.units.(fields{VarCt});
end

end