# POLPREDgetAPI
A function to get tide data from the  Polpred API, writen in MATLAB.

The NOC Polpred API allows you retrieve tidal data for offshore locations around the world. The data returned is computed at the time the request is called, using the oceanographic models available. The demonstration key uses the CS3X (Extended Area Continental Shelf Model) for the area of the South of Ireland and South-West of the UK.
The API documentation is here: https://apps.noc-innovations.co.uk/docs/polpred-api/index.html

Data can be requested for time series ('TS'), spatial area ('SA') or port time series ('PTS'), or a list of the available ports ('PL').
