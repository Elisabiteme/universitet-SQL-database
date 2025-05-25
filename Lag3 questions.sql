--2. Find the highest salary of an instructor. 
SELECT MAX(salary) AS highest_salary FROM instructor;

--Hvis jeg også vil ha navn på den med høyeste lønn. 
SELECT name, salary
FROM instructor
WHERE salary = (SELECT MAX(salary) FROM instructor);

--3)	Increase the salary of each instructor in the ‘Comp. Sci.’ department by 10%.

/*returns a relation that is the same as the instructor relation, 
except that the attribute salary is multiplied by 1.1. 
This shows what would result if we gave a 10% raise to each instructor*/

SELECT name, dept_name, salary, salary*1.10 FROM instructor WHERE dept_name = 'Comp. Sci.';

/*4)	Delete all courses that have never been offered (that is, do not occur in the section relation).*/

--Undersøker først tabellene
SELECT* FROM section
SELECT* FROM course

/*Bruker FULL JOIN for å matche de to tabellene, course og section, 
på/ON course id for å finne ut hvor det er missing values.*/ 

SELECT course.course_id, section.course_id
FROM course
FULL JOIN section
ON course.course_id = section.course_id;

--Resultat: Bio-399 finnes ikke i section tabellen. 

--Sletter dette kurset i course tabellen: 

DELETE FROM course
WHERE course_id = 'BIO-399'


/*I stedet for koden over for å slette burder jeg heller brukt TRANSACTION (best practise)*/

START TRANSACTION;  -- Starter en transaksjon
DELETE FROM course WHERE course_id = 'BIO-399';

-- Hvis alt ser bra ut, lagre endringene:
COMMIT;

--Hvis jeg vil angre kan jeg gjøre det slik, men da må jeg gjøre det før jeg kjører commit i linjen over. 
START TRANSACTION;
DELETE FROM course WHERE course_id = 'BIO-399';
ROLLBACK; -- Angrer slettingen

/* 5)	Insert every student whose tot_cred attribute is greater than 100 as an 
instructor in the same department, with a salary of $10,000. */
SELECT* FROM instructor
SELECT* FROM teaches

START TRANSACTION;

INSERT INTO instructor (student.ID, student.name, student.dept_name, instructor.salary)
SELECT ID, name, dept_name, 10000
FROM student
WHERE tot_cred > 100;


/*6)	Consider the following SQL query that seeks to find a list of titles of all courses 
taught in Spring 2017 along with the name of the instructor. */

SELECT name, title 
FROM instructor 
NATURAL JOIN teaches 
NATURAL JOIN section 
NATURAL JOIN course 
WHERE semester = 'Spring' AND year = 2017;

/*Feil i koden: 
Title finnes ikke. Men title finnes heller i tabellen Course. 
Incorrect Use of NATURAL JOIN: 
NATURAL JOIN automatically joins tables using all columns with the same name.
If instructor, teaches, section, and course have multiple matching column names 
(e.g., ID, course_id), the query may join incorrectly.
If the column names do not match exactly across tables, the query will fail.
In addition, it is incorerct use of quotes for spring*/

--Må først ENDRE NAVN på ID til instructor_id, for har problemer med ID. Kan være fordi det er store bokstaver. 
--Sjekker først at ID eksisterer, og det gjør det.

SELECT column_name 
FROM information_schema.columns 
WHERE table_name = 'instructor' 

SELECT column_name 
FROM information_schema.columns 
WHERE table_name = 'teaches';

--endrer navn ID til navn id_instructor i to tabeller (instructor og teaches)

ALTER TABLE instructor RENAME COLUMN "ID" TO instructor_id;
ALTER TABLE teaches RENAME COLUMN "ID" TO instructor_id;

--sjekker at oppdateringene er gjort

SELECT column_name 
FROM information_schema.columns 
WHERE table_name = 'instructor';

SELECT column_name 
FROM information_schema.columns 
WHERE table_name = 'teaches';

--Gjør endringene som må til. 
SELECT i.name, c.title, i.dept_name  
FROM instructor i
JOIN teaches t ON i.instructor_id = t.instructor_id 
JOIN section s ON t.course_id = s.course_id AND t.sec_id = s.sec_id AND t.semester = s.semester AND t.year = s.year
JOIN course c ON s.course_id = c.course_id AND t.course_id= c.course_id AND i.dept_name=c.dept_name
WHERE s.semester = 'Spring' AND s.year = 2017;

SELECT* FROM section

/*7)	Display a list of all instructors, showing each instructor's 
name and the number of sections taught. Make sure to show the number of sections as 0 
for instructors who have not taught any section. 
Your query should use an outer join (FULL OUTER JOIN), and should not use subqueries.*/


SELECT i.name, 
       COALESCE(COUNT(s.course_id), 0) AS count_sections --count_sections -antall undervisninger 
FROM instructor i
FULL OUTER JOIN teaches t ON i.instructor_id = t.instructor_id
FULL OUTER JOIN section s ON t.course_id = s.course_id 
                           AND t.sec_id = s.sec_id 
                           AND t.semester = s.semester 
                           AND t.year = s.year
GROUP BY i.instructor_id, i.name
ORDER BY num_sections DESC;



/*8)	Display the list of all departments, with the total number of instructors 
in each department, without using subqueries. 
Make sure to show departments that have no instructors and 
list those departments with an instructor count of zero.*/

SELECT dept_name, 
       COALESCE(COUNT(instructor_id), 0) AS count_instructors  --num_sections er ny kolonne med antall seksjoner undervist i. 
FROM instructor i
GROUP BY dept_name
ORDER BY count_instructors DESC;

/*9)	You need to create a relation grade_points (grade, points) 
that provides a conversion from letter grades in the takes relation to numeri scores. 
For example, an A grade could be specified to correspond to 4 points, an A- to 3.7 points, 
a B+ to 3.3 points, a B to 3 points, B to 3 points, B- to 2.7, C+ to 2.3, C to 2, C- to 1.7, D+ to 1.3, D to 1, and F to 0.*/

--SQL Code to Create the grade_points Table

CREATE TABLE grade_points (
    grade CHAR(2) PRIMARY KEY,  -- Grade as a primary key (e.g., A, A-, B+)
    points DECIMAL(3, 1) NOT NULL  -- Numerical points with one decimal place
);


--SQL Code to Insert Values

INSERT INTO grade_points (grade, points) VALUES
('A', 4.0),
('A-', 3.7),
('B+', 3.3),
('B', 3.0),
('B-', 2.7),
('C+', 2.3),
('C', 2.0),
('C-', 1.7),
('D+', 1.3),
('D', 1.0),
('F', 0.0);

--sjekker at det ble riktig
SELECT* FROM grade_points


/*10)	Now you need to create a view student_grades (ID, GPA) 
giving the grade-point average of each student. 
Make sure that your view definition corretly handles 
the case of NULL values for the ‘grade’ attribute of the ‘takes’ relation.*/


SELECT* FROM grade_points
SELECT* FROM takes

--Tabellen takes inneholder ID. Endrer denne til student_id. 
ALTER TABLE takes RENAME COLUMN "ID" TO student_id;


CREATE VIEW student_grades AS
SELECT 
    t.student_id, 
    COALESCE(AVG(g.points), 0) AS GPA  -- Use COALESCE to handle NULL grades
FROM takes t
LEFT JOIN grade_points g ON t.grade = g.grade  -- Join with grade_points to get numerical points
WHERE t.grade IS NOT NULL  -- Ignore rows where grade is NULL
GROUP BY t.student_id;

--FÅR IKKE SETT TABELLEN SELV. FOR Å SE OM DEN STEMMER - kjør koden uten view ved å droppe første linje i koden over. 




--brukes for å avslutte kjøringen, hvis den ikke er avsluttet.  
ROLLBACK;


