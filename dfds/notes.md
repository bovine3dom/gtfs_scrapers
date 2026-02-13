timetables here https://www.dfds.com/en/passenger-ferries/passenger-information/timetables

that page fires off a _wild_ number of requests to pages like https://api.hellman.oxygen.dfds.cloud/prod/servicesunifiedbff/api/v2/departures?fromDate=2026-02-16T00%3A00%3A01Z&portCode=CQF&toDate=2026-02-22T23%3A59%3A59Z


```
{"departures":[{"departureId":"0a681908-b98b-407d-b726-10b2ee9137cd","scheduledDepartureTime":"2026-02-02T21:00:00Z","scheduledArrivalTime":"2026-02-03T20:00:00Z","route":{"departurePort":{"code":"ROS","name":"Rosslare","unlocode":"IEROE","timezone":"Europe/Dublin"},"arrivalPort":{"code":"DKK","name":"Dunkirk","unlocode":"FRDKK","timezone":"Europe/Paris"}}},{"departureId":"811116f3-bd68-4ca7-bf6d-6fc01fe66cba","scheduledDepartureTime":"2026-02-03T23:55:00Z","scheduledArrivalTime":"2026-02-04T22:55:00Z","route":{"departurePort":{"code":"ROS","name":"Rosslare","unlocode":"IEROE","timezone":"Europe/Dublin"},"arrivalPort":{"code":"DKK","name":"Dunkirk","unlocode":"FRDKK","timezone":"Europe/Paris"}}},{"departureId":"878d3b27-8afb-44cb-ba35-1585005310de","scheduledDepartureTime":"2026-02-05T03:30:00Z","scheduledArrivalTime":"2026-02-06T02:00:00Z","route":{"departurePort":{"code":"ROS","name":"Rosslare","unlocode":"IEROE","timezone":"Europe/Dublin"},"arrivalPort":{"code":"DKK","name":"Dunkirk","unlocode":"FRDKK","timezone":"Europe/Paris"}}},{"departureId":"51268539-d641-4e77-a449-4e81122a3139","scheduledDepartureTime":"2026-02-06T22:30:00Z","scheduledArrivalTime":"2026-02-07T21:30:00Z","route":{"departurePort":{"code":"ROS","name":"Rosslare","unlocode":"IEROE","timezone":"Europe/Dublin"},"arrivalPort":{"code":"DKK","name":"Dunkirk","unlocode":"FRDKK","timezone":"Europe/Paris"}}},{"departureId":"6310a698-7472-4d88-906e-526bb3ef29df","scheduledDepartureTime":"2026-02-08T00:55:00Z","scheduledArrivalTime":"2026-02-08T23:55:00Z","route":{"departurePort":{"code":"ROS","name":"Rosslare","unlocode":"IEROE","timezone":"Europe/Dublin"},"arrivalPort":{"code":"DKK","name":"Dunkirk","unlocode":"FRDKK","timezone":"Europe/Paris"}}}]}
```

i can't find any list of port codes anywhere so i guess hardcode them?

AMS
CQF
DKK
DPP
DVR
JER
KAN
KEL
KLJ
KPS
NEW
NHN
PLA
PME
POO
ROS
STM
TRG
