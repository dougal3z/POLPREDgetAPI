# POLPREDgetAPI
A function to get tide data from the  Polpred API, writen in MATLAB.

The NOC Polpred API allows you retrieve tidal data for offshore locations around the world. The data returned is computed at the time the request is called, using the oceanographic models available. The demonstration key uses the CS3X (Extended Area Continental Shelf Model) for the area of the South of Ireland and South-West of the UK.
The API documentation is here: https://apps.noc-innovations.co.uk/docs/polpred-api/index.html

Data can be requested for time series ('TS'), spatial area ('SA') or port time series ('PTS'), or a list of the available ports ('PL').

e.g.

POLPREDgetAPI_1_3([],'PL')

ans =

  768×3 table

             Name             Latitude    Longitude
    ______________________    ________    _________

    {'Aasiaat, Greenland'}      68.71      -52.883 
    {'Abashiri'          }     44.017       144.28 
    {'Aberdeen'          }     57.143      -2.0767 
    {'Aberystwyth'       }       52.4      -4.0833 
    {'Abidjan Vridi'     }     5.2417           -4 

              :                  :            :    

    {'Yokohama'          }     35.467       139.63 
    {'Yonaguni'          }      24.45       122.95 
    {'Ystad'             }     55.417       13.817 
    {'Zanzibar'          }     -6.155        39.19 
    {'Zhapo'             }     21.583       111.83 

	Display all 768 rows.
