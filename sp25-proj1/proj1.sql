-- Before running drop any existing views
DROP VIEW IF EXISTS q0;
DROP VIEW IF EXISTS q1i;
DROP VIEW IF EXISTS q1ii;
DROP VIEW IF EXISTS q1iii;
DROP VIEW IF EXISTS q1iv;
DROP VIEW IF EXISTS q2i;
DROP VIEW IF EXISTS q2ii;
DROP VIEW IF EXISTS q2iii;
DROP VIEW IF EXISTS q3i;
DROP VIEW IF EXISTS q3ii;
DROP VIEW IF EXISTS q3iii;
DROP VIEW IF EXISTS q4i;
DROP VIEW IF EXISTS q4ii;
DROP VIEW IF EXISTS q4iii;
DROP VIEW IF EXISTS q4iv;
DROP VIEW IF EXISTS q4v;

-- Question 0
CREATE VIEW q0(era)
AS
  SELECT MAX(era)
  FROM pitching
;

-- Question 1i
CREATE VIEW q1i(namefirst, namelast, birthyear)
AS
  SELECT namefirst, namelast, birthyear
  FROM people
  WHERE weight > 300
;

-- Question 1ii
CREATE VIEW q1ii(namefirst, namelast, birthyear)
AS
  SELECT namefirst, namelast, birthyear
  FROM people
  WHERE namefirst LIKE '% %'
  ORDER BY namefirst, namelast
;

-- Question 1iii
CREATE VIEW q1iii(birthyear, avgheight, count)
AS
  SELECT birthyear, AVG(height), COUNT(*)
  FROM people
  GROUP BY birthyear
  ORDER BY birthyear ASC
;

-- Question 1iv
CREATE VIEW q1iv(birthyear, avgheight, count)
AS
  SELECT birthyear, AVG(height), COUNT(*)
  FROM people
  GROUP BY birthyear
  HAVING AVG(height) > 70
  ORDER BY birthyear ASC
;

-- Question 2i
CREATE VIEW q2i(namefirst, namelast, playerid, yearid)
AS
  SELECT p.namefirst, p.namelast, p.playerid, h.yearid 
  FROM people AS p
  INNER JOIN halloffame AS h
  ON p.playerid = h.playerid
  WHERE h.inducted = 'Y'
  ORDER BY h.yearid DESC, p.playerid ASC
;

-- Question 2ii
CREATE VIEW q2ii(namefirst, namelast, playerid, schoolid, yearid)
AS
  SELECT p.namefirst, p.namelast, p.playerid, c.schoolid, h.yearid
  FROM people AS p
  INNER JOIN halloffame AS h ON p.playerid = h.playerid
  INNER JOIN collegeplaying AS c ON p.playerid = c.playerid
  INNER JOIN schools AS s ON c.schoolid = s.schoolid
  WHERE h.inducted = 'Y' AND s.schoolstate = 'CA'
  ORDER BY h.yearid DESC, s.schoolid ASC, p.playerid ASC
;

-- Question 2iii
CREATE VIEW q2iii(playerid, namefirst, namelast, schoolid)
AS
  SELECT p.playerid, p.namefirst, p.namelast, c.schoolid 
  FROM people AS p 
  INNER JOIN halloffame AS h ON p.playerid = h.playerid
  LEFT JOIN collegeplaying AS c ON p.playerid = c.playerid
  WHERE h.inducted = 'Y'
  ORDER BY p.playerid DESC, c.schoolid ASC
;

-- Question 3i
CREATE VIEW q3i(playerid, namefirst, namelast, yearid, slg)
AS
  SELECT p.playerid, p.namefirst, p.namelast, b.yearid,
    ( (b.H - b.H2B - b.H3B - b.HR) * 1.0 + b.H2B * 2.0 + b.H3B * 3.0 + b.HR * 4.0 ) / b.AB AS slg
  FROM people AS p
  INNER JOIN batting AS b ON p.playerid = b.playerid
  WHERE b.AB > 50
  ORDER BY slg DESC, b.yearid ASC, p.playerid ASC
  LIMIT 10
;

-- Question 3ii
CREATE VIEW q3ii(playerid, namefirst, namelast, lslg)
AS
  SELECT p.playerid, p.namefirst, p.namelast,
    (SUM(b.H) + SUM(b.H2B) + 2 * SUM(b.H3B) + 3 * SUM(b.HR)) * 1.0 / SUM(b.AB) AS lslg
  FROM people AS p 
  INNER JOIN batting AS b ON p.playerid = b.playerid
  GROUP BY p.playerid
  HAVING SUM(b.AB) > 50
  ORDER BY lslg DESC, p.playerid ASC 
  LIMIT 10
;

-- Question 3iii
CREATE VIEW q3iii(namefirst, namelast, lslg)
AS
  SELECT p.namefirst, p.namelast,
    (SUM(b.H) + SUM(b.H2B) + 2 * SUM(b.H3B) + 3 * SUM(b.HR)) * 1.0 / SUM(b.AB) AS lslg
  FROM people AS p 
  INNER JOIN batting AS b ON p.playerid = b.playerid
  GROUP BY p.playerid
  HAVING
    SUM(b.AB) > 50 AND lslg > (
      SELECT (SUM(H) + SUM(H2B) + 2 * SUM(H3B) + 3 * SUM(HR)) * 1.0 / SUM(AB)
      FROM batting
      WHERE playerID = 'mayswi01'
    )
;

-- Question 4i
CREATE VIEW q4i(yearid, min, max, avg)
AS
  SELECT yearid, MIN(salary), MAX(salary), AVG(salary)
  FROM salaries
  GROUP BY yearid
  ORDER BY yearid ASC
;

-- Question 4ii
CREATE VIEW q4ii(binid, low, high, count) 
AS
WITH 
  SalaryInfo AS (
    SELECT
      MIN(salary) AS min_s,
      MAX(salary) AS max_s,
      (MAX(salary) - MIN(salary)) / 10.0 AS width
    FROM salaries
    WHERE yearid = 2016
  ),
  Bins (binid) AS (
    SELECT 0
    UNION ALL
    SELECT binid + 1
    FROM Bins
    WHERE binid < 9
  ),
  BinnedSalaries AS (
    SELECT
      CASE
        WHEN s.salary = i.max_s THEN 9
        ELSE CAST((s.salary - i.min_s) / i.width AS INT)
      END AS binid
    FROM salaries AS s, SalaryInfo AS i
    WHERE s.yearid = 2016 AND s.salary IS NOT NULL
  ),
  BinCounts AS (
    SELECT binid, COUNT(*) AS num
    FROM BinnedSalaries
    GROUP BY binid
  )
  SELECT
    b.binid,
    i.min_s + b.binid * i.width AS low,
    i.min_s + (b.binid + 1) * i.width AS high,
    COALESCE(c.num, 0) AS count
  FROM Bins AS b
  CROSS JOIN SalaryInfo AS i 
  LEFT JOIN BinCounts AS c ON b.binid = c.binid
  ORDER BY b.binid
;

-- Question 4iii
CREATE VIEW q4iii(yearid, mindiff, maxdiff, avgdiff)
AS
WITH YearlyStats AS (
  SELECT
    yearid,
    MIN(salary) AS min_s,
    MAX(salary) AS max_s,
    AVG(salary) AS avg_s
  FROM salaries
  GROUP BY yearid
)
SELECT 
  current_year.yearid,
  current_year.min_s - previous_year.min_s AS mindiff,
  current_year.max_s - previous_year.max_s AS maxdiff,
  current_year.avg_s - previous_year.avg_s AS avgdiff
FROM YearlyStats AS current_year
INNER JOIN YearlyStats AS previous_year ON current_year.yearid = previous_year.yearid + 1
GROUP BY current_year.yearid
;

-- Question 4iv
CREATE VIEW q4iv(playerid, namefirst, namelast, salary, yearid)
AS
  SELECT p.playerid, p.namefirst, p.namelast, s.salary, s.yearid
  FROM people AS p 
  INNER JOIN salaries AS s ON s.playerid = p.playerid
  WHERE (s.yearid, s.salary) IN (
    SELECT yearid, MAX(salary) 
    FROM salaries
    WHERE yearid IN (2000, 2001)
    GROUP BY yearid
  )
;

-- Question 4v
CREATE VIEW q4v(team, diffAvg) AS
  SELECT a.teamid, MAX(s.salary) - MIN(s.salary)
  FROM allstarfull AS a 
  INNER JOIN salaries AS s ON a.playerid = s.playerid AND a.yearid = s.yearid
  WHERE a.yearid = 2016
  GROUP BY a.teamid
;

