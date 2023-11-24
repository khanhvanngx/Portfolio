-- Database: citilink
-- Retrive information for each bus operating in the second quarter of 2019
SELECT
    PlateNo AS Bus_Plate
    , MONTH(TDate) AS Month
    , MAX(EndTime) AS Finishing_Time
    , COUNT(*) AS Number_Of_Trip
    , COUNT(DISTINCT DID) AS Number_Of_Driver
FROM bustrip
WHERE TDate >='2019-04-01'
AND TDate < '2019-07-01'
GROUP BY PlateNo, MONTH(TDate)
ORDER BY PlateNo;

-- Query all bus stops that contain the word "Bridge" in the "address" or "description" of the bus stop, and find information about bus routes through those bus stops.
-- Continue to query another column named Check, to check "Trip frequency of the day of the week" corresponding to each bus route
SELECT
    stop.StopID
    , stop.LocationDes 
    , stop.Address
    , stoprank.SID 
    , CASE 
        WHEN service.Normal = 1 THEN 'Normal'
        ELSE 'Express'
    END AS [Type]
    , normal.WeekdayFreq AS WeekdayFreq
    , CASE 
        WHEN normal.WeekdayFreq > 15 THEN 'High'
        WHEN normal.WeekdayFreq < 10 THEN 'Low'
        ELSE 'Medium'
    END AS [Check]
FROM stop
FULL JOIN stoprank ON stop.StopID = stoprank.StopID
LEFT JOIN service ON service.SID = stoprank.SID
LEFT JOIN normal ON normal.SID = service.SID
WHERE stop.LocationDes LIKE '%Bridge%'
OR stop.Address LIKE '%Bridge%'
ORDER BY stop.StopID, service.SID ASC;

-- Write a query to find old bus cards that have been replaced by bus cards new card along with corresponding accompanying information of the new Card and old Card
WITH CARD AS
(
    SELECT
        CardID
        , Expiry
        , OldCardID
    FROM citylink
    WHERE OldCardID IS NOT NULL
)
, COUNT_RIDE AS
(
    SELECT
        CardID
        , COUNT(*) AS Cnt_ride
    FROM ride
    GROUP BY CardID
)

SELECT
    CARD.*
    , ISNULL(count_ride_1.Cnt_ride, 0) AS NumberOfRide
    , ISNULL(count_ride_2.Cnt_ride, 0) AS NumberOfRide_Old
FROM CARD
LEFT JOIN COUNT_RIDE AS count_ride_1
ON CARD.CardID = count_ride_1.CardID
LEFT JOIN COUNT_RIDE AS count_ride_2
ON CARD.OldCardID = count_ride_2.CardID;