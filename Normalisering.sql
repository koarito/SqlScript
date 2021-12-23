use stidb;
--DROP TABLE IF EXISTS UNF;
CREATE TABLE `UNF` (
    `Id` DECIMAL(38, 0) NOT NULL,
    `Name` VARCHAR(26) NOT NULL,
    `Grade` VARCHAR(11) NOT NULL,
    `Hobbies` VARCHAR(25),
    `City` VARCHAR(10) NOT NULL,
    `School` VARCHAR(20) NOT NULL,
    `HomePhone` VARCHAR(12),
    `JobPhone` VARCHAR(12),
    `MobilePhone1` VARCHAR(12),
    `MobilePhone2` VARCHAR(12)
);
--LOAD DATA INFILE '/var/lib/mysql-files/denormalized-data.csv'
--INTO TABLE UNF 
--FIELDS TERMINATED BY ','
--ENCLOSED BY '"'
--LINES TERMINATED BY '\n'
--IGNORE 1 ROWS;

DROP TABLE IF EXISTS Student;
CREATE TABLE Student SELECT DISTINCT ID, NAME FROM UNF;
ALTER TABLE Student ADD PRIMARY KEY (Id);
ALTER TABLE Student MODIFY Id INTEGER NOT NULL AUTO_INCREMENT;

DROP TABLE IF EXISTS School;
  CREATE TABLE School SELECT DISTINCT 0 AS Id, School as Name, City FROM UNF;
SET @incrementValue := 0;
UPDATE School SET Id = (SELECT @incrementValue := @incrementValue +1);
ALTER TABLE School ADD PRIMARY KEY (Id);
ALTER TABLE School MODIFY Id INTEGER NOT NULL AUTO_INCREMENT;
DROP TABLE IF EXISTS Student_School;
CREATE TABLE Student_School 
SELECT DISTINCT 
UNF.Id AS StudentId,
School.Id AS SchoolId 
FROM UNF 
INNER JOIN School ON UNF.School = School.Name;


CREATE VIEW HobbyUNF AS
SELECT Id, Hobbies,
Trim(SUBSTRING_INDEX(Hobbies, ",", 1)) AS Hobby FROM UNF
UNION
SELECT Id, Hobbies,
Trim(SUBSTRING_INDEX(SUBSTRING_INDEX(Hobbies, ",", -2),"," ,1)) FROM UNF
WHERE (LENGTH(Hobbies) - LENGTH(REPLACE(Hobbies, ',', ''))=2)
UNION
SELECT Id, Hobbies,
Trim(SUBSTRING_INDEX(Hobbies, ",", -1)) FROM UNF
WHERE (LENGTH(Hobbies) - LENGTH(REPLACE(Hobbies, ',', ''))>=1); 
CREATE TABLE Hobby AS
SELECT DISTINCT 0 AS Id, Hobby AS Name FROM HobbyUNF WHERE Hobby <> "";
DELETE FROM Hobby WHERE Name = "Nothing";
SET @incrementValue = 0;
UPDATE Hobby set Id = (select @incrementValue := @incrementValue + 1);
ALTER TABLE Hobby ADD PRIMARY KEY(Id);
ALTER TABLE Hobby MODIFY Id INTEGER NOT NULL AUTO_INCREMENT;
CREATE TABLE Student_Hobby AS
SELECT HobbyUNF.Id AS StudentId, Hobby.Id AS HobbyId
FROM HobbyUNF INNER JOIN Hobby
ON HobbyUNF.Hobby = Hobby.Name;

CREATE TABLE Student_Phone 
SELECT Id AS StudentId, 1 AS PhoneId, HomePhone AS Phone FROM UNF
UNION
SELECT Id, 2, JobPhone FROM UNF
UNION
SELECT Id, 3, MobilePhone1 FROM UNF
UNION
SELECT Id, 3, MobilePhone2 FROM UNF;
DELETE FROM Student_Phone WHERE Phone = "";
CREATE TABLE Phone
SELECT DISTINCT PhoneId AS Id, "Home" AS Type FROM Student_Phone WHERE PhoneId = 1
UNION
SELECT DISTINCT PhoneId, "Job" FROM Student_Phone WHERE PhoneId = 2
UNION
SELECT DISTINCT PhoneId, "Mobile" FROM Student_Phone WHERE PhoneId = 3;
ALTER TABLE Phone ADD PRIMARY KEY (Id);
ALTER TABLE Phone MODIFY Id INTEGER NOT NULL AUTO_INCREMENT;
--CREATE VIEW Hobby2_0
DROP VIEW IF EXISTS Hobby2;
CREATE VIEW Hobby2 AS
SELECT Student_Hobby.StudentId
--,Student_Hobby.HobbyId
,GROUP_CONCAT(Hobby.Name) as Hobbies
FROM Student_Hobby
LEFT JOIN Hobby ON Student_Hobby.HobbyId = Hobby.Id
GROUP BY Student_Hobby.StudentId
;

DROP VIEW IF EXISTS Phone2;
CREATE VIEW Phone2 AS 
SELECT Student_Phone.StudentId
,GROUP_CONCAT(Student_Phone.Phone) AS Phones
FROM Student_Phone
LEFT JOIN Phone ON Student_Phone.PhoneId = Phone.Id
GROUP BY Student_Phone.StudentId
;
DROP VIEW IF EXISTS UNF2
CREATE VIEW UNF2 AS
SELECT 
Student_School.StudentId AS Id
,Student.Name 
,School.Name AS School
,IF(Hobby2.Hobbies IS NULL,"n/a",Hobby2.Hobbies) AS Hobbies
,Phone2.Phones
FROM Student_School
LEFT JOIN Student
ON Student_School.Studentid = Student.id
LEFT JOIN School
ON Student_School.Schoolid = School.Id
LEFT JOIN Hobby2
ON Student_School.StudentId = Hobby2.StudentId
LEFT JOIN Phone2
ON Student_School.StudentId = Phone2.StudentId
;
