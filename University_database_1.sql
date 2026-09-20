 Use University_database_1

create table department
(
  dept_name varchar(30) NOT Null,
  building char(20),
  budget int check (budget>0),
  constraint dept_PK primary key (dept_name)
);

create table course(
  course_id nvarchar(25) not null primary key,
  title char(50) not null,
  dept_name varchar(30),
  credits decimal(3,2) check (credits>0) ,
  foreign key (dept_name) references department(dept_name),
  constraint uq_course_title UNIQUE(title)
);

create table student(
  ID bigint not null primary key,
  name varchar(40),
  dept_name varchar(30) foreign key references department(dept_name),
  tot_cred smallint check (tot_cred >=0)
);

create table instructor(
  ID bigint not null primary key,
  name char(40) not null,
  dept_name varchar(30),
  salary int check (salary>0),
  constraint ins_FK foreign key (dept_name) references department(dept_name)
);

create table advisor(
  s_id bigint not null,
  i_id bigint,
  constraint ad_PK primary key(s_id),
  constraint ad_FK1 foreign key(s_id) references student(ID),
  constraint ad_FK2 foreign key(i_id) references instructor(ID)
);

create table prereq(
  course_id nvarchar(25) not null foreign key references course(course_id),
  prereq_id nvarchar(25) not null foreign key references course(course_id),
  constraint pre_PK primary key(course_id,prereq_id)
);

create table classroom(
  building char(10) not null,
  room_number smallint not null,
  capacity int check (capacity>0),
  constraint cr_pk primary key (building, room_number)
);

create table section(
   course_id nvarchar(25) not null foreign key references course(course_id),
   sec_id nchar(10) not null,
   semester varchar(15) not null,
   year smallint not null,
   building char(10),
   room_number smallint,
   time_slot_id char(1),
   constraint sec_PK primary key(course_id, sec_id, semester, year),
   constraint sec_FK foreign key (building, room_number) references classroom(building,room_number),
   constraint chk_semester check(semester IN ('Spring','Summer','Fall')),
   CONSTRAINT uq_section UNIQUE(building, room_number, time_slot_id, semester, year)
);

create table takes(
  ID bigint foreign key references student(ID),
  course_id nvarchar(25),
  sec_id nchar(10),
  semester varchar(15),
  year smallint,
  grade varchar(2),
  constraint takes_PK primary key(ID, course_id, sec_id, semester, year),
  constraint takes_FK foreign key(course_id,sec_id, semester, year)references section(course_id,sec_id, semester, year),
  constraint chk_grade check (grade >= 0 AND grade <= 4.00)
);

create table teaches(
  ID bigint foreign key references instructor(ID),
  course_id nvarchar(25),
  sec_id nchar(10),
  semester varchar(15),
  year smallint,
  constraint teaches_PK primary key (ID, course_id, sec_id, semester, year),
  constraint teaches_FK foreign key (course_id, sec_id, semester, year) references section(course_id, sec_id, semester, year)
);

create table time_slot(
  time_slot_id char(1) not null,
  day char(2) not null,
  start_time time not null,
  end_time time,
  constraint ts_pk primary key (time_slot_id, day, start_time),
  constraint chk_time check(end_time>start_time),
  constraint chk_day check(day IN ('M','T','W','R','F','S','U')),
  constraint uq_timeslot UNIQUE(time_slot_id, day)
);


ALTER TABLE takes
DROP CONSTRAINT chk_grade;

ALTER TABLE takes
ADD CONSTRAINT chk_grade CHECK (grade IN ('A', 'A-', 'B+', 'B', 'B-', 'C+', 'C', 'C-', 'D+', 'D', 'F'));


INSERT INTO department (dept_name, building, budget) VALUES ('Biology', 'Watson', 90000)
INSERT INTO department (dept_name, building, budget) VALUES ('Comp. Sci.', 'Taylor', 100000)
INSERT INTO department (dept_name, building, budget) VALUES ('Elec. Eng.', 'Taylor', 85000)
INSERT INTO department (dept_name, building, budget) VALUES ('Finance', 'Painter', 120000)
INSERT INTO department (dept_name, building, budget) VALUES ('History', 'Painter', 50000)
INSERT INTO department (dept_name, building, budget) VALUES ('Music', 'Packard', 80000)
INSERT INTO department (dept_name, building, budget) VALUES ('Physics', 'Watson', 70000)

Go

INSERT INTO course (course_id, title, dept_name, credits) VALUES ('BIO-101', 'Intro. to Biology', 'Biology', 4.00)
INSERT INTO course (course_id, title, dept_name, credits) VALUES ('BIO-301', 'Genetics', 'Biology', 4.00)
INSERT INTO course (course_id, title, dept_name, credits) VALUES ('BIO-399', 'Computational Biology', 'Biology', 3.00)
INSERT INTO course (course_id, title, dept_name, credits) VALUES ('CS-101', 'Intro. to Computer Science', 'Comp. Sci.', 4.00)
INSERT INTO course (course_id, title, dept_name, credits) VALUES ('CS-190', 'Game Design', 'Comp. Sci.', 4.00)
INSERT INTO course (course_id, title, dept_name, credits) VALUES ('CS-315', 'Robotics', 'Comp. Sci.', 3.00)
INSERT INTO course (course_id, title, dept_name, credits) VALUES ('CS-319', 'Image Processing', 'Comp. Sci.', 3.00)
INSERT INTO course (course_id, title, dept_name, credits) VALUES ('CS-347', 'Database System Concepts', 'Comp. Sci.', 3.00)
INSERT INTO course (course_id, title, dept_name, credits) VALUES ('EE-181', 'Intro. to Digital Systems', 'Elec. Eng.', 3.00)
INSERT INTO course (course_id, title, dept_name, credits) VALUES ('FIN-201', 'Investment Banking', 'Finance', 3.00)
INSERT INTO course (course_id, title, dept_name, credits) VALUES ('HIS-351', 'World History', 'History', 3.00)
INSERT INTO course (course_id, title, dept_name, credits) VALUES ('MU-199', 'Music Video Production', 'Music', 3.00)
INSERT INTO course (course_id, title, dept_name, credits) VALUES ('PHY-101', 'Physical Principles', 'Physics', 4.00)

GO

INSERT INTO student (ID, name, dept_name, tot_cred) VALUES (128, 'Zhang', 'Comp. Sci.', 102)
INSERT INTO student (ID, name, dept_name, tot_cred) VALUES (12345, 'Shankar', 'Comp. Sci.', 32)
INSERT INTO student (ID, name, dept_name, tot_cred) VALUES (19991, 'Brandt', 'History', 80)
INSERT INTO student (ID, name, dept_name, tot_cred) VALUES (23121, 'Chavez', 'Finance', 110)
INSERT INTO student (ID, name, dept_name, tot_cred) VALUES (44553, 'Peltier', 'Physics', 56)
INSERT INTO student (ID, name, dept_name, tot_cred) VALUES (45678, 'Levy', 'Physics', 46)
INSERT INTO student (ID, name, dept_name, tot_cred) VALUES (54321, 'Williams', 'Comp. Sci.', 54)
INSERT INTO student (ID, name, dept_name, tot_cred) VALUES (55739, 'Sanchez', 'Music', 38)
INSERT INTO student (ID, name, dept_name, tot_cred) VALUES (70557, 'Snow', 'Physics', 0)
INSERT INTO student (ID, name, dept_name, tot_cred) VALUES (76543, 'Brown', 'Comp. Sci.', 58)
INSERT INTO student (ID, name, dept_name, tot_cred) VALUES (76653, 'Aoi', 'Elec. Eng.', 60)
INSERT INTO student (ID, name, dept_name, tot_cred) VALUES (98765, 'Bourikas', 'Elec. Eng.', 98)
INSERT INTO student (ID, name, dept_name, tot_cred) VALUES (98988, 'Tanaka', 'Biology', 120)

GO

INSERT INTO instructor (ID, name, dept_name, salary) VALUES (10101, 'Srinivasan', 'Comp. Sci.', 65000)
INSERT INTO instructor (ID, name, dept_name, salary) VALUES (12121, 'Wu', 'Finance', 90000)
INSERT INTO instructor (ID, name, dept_name, salary) VALUES (15151, 'Mozart', 'Music', 40000)
INSERT INTO instructor (ID, name, dept_name, salary) VALUES (22222, 'Einstein', 'Physics', 95000)
INSERT INTO instructor (ID, name, dept_name, salary) VALUES (32343, 'El Said', 'History', 60000)
INSERT INTO instructor (ID, name, dept_name, salary) VALUES (33456, 'Gold', 'Physics', 87000)
INSERT INTO instructor (ID, name, dept_name, salary) VALUES (45565, 'Katz', 'Comp. Sci.', 75000)
INSERT INTO instructor (ID, name, dept_name, salary) VALUES (58583, 'Califieri', 'History', 62000)
INSERT INTO instructor (ID, name, dept_name, salary) VALUES (76543, 'Singh', 'Finance', 80000)
INSERT INTO instructor (ID, name, dept_name, salary) VALUES (76766, 'Crick', 'Biology', 72000)
INSERT INTO instructor (ID, name, dept_name, salary) VALUES (83821, 'Brandt', 'Comp. Sci.', 92000)
INSERT INTO instructor (ID, name, dept_name, salary) VALUES (98345, 'Kim', 'Elec. Eng.', 80000)

GO

INSERT INTO advisor (s_id, i_id) VALUES (00128, 45565)
INSERT INTO advisor (s_id, i_id) VALUES (12345, 10101)
INSERT INTO advisor (s_id, i_id) VALUES (23121, 76543)
INSERT INTO advisor (s_id, i_id) VALUES (44553, 22222)
INSERT INTO advisor (s_id, i_id) VALUES (45678, 22222)
INSERT INTO advisor (s_id, i_id) VALUES (76543, 45565)
INSERT INTO advisor (s_id, i_id) VALUES (76653, 98345)
INSERT INTO advisor (s_id, i_id) VALUES (98765, 98345)
INSERT INTO advisor (s_id, i_id) VALUES (98988, 76766)

GO

INSERT INTO classroom (building, room_number, capacity) VALUES ('Packard', 101, 500)
INSERT INTO classroom (building, room_number, capacity) VALUES ('Painter', 514, 10)
INSERT INTO classroom (building, room_number, capacity) VALUES ('Taylor', 3128, 70)
INSERT INTO classroom (building, room_number, capacity) VALUES ('Watson', 100, 30)
INSERT INTO classroom (building, room_number, capacity) VALUES ('Watson', 120, 50)

GO

INSERT INTO prereq (course_id, prereq_id) VALUES ('BIO-301', 'BIO-101')
INSERT INTO prereq (course_id, prereq_id) VALUES ('BIO-399', 'BIO-101')
INSERT INTO prereq (course_id, prereq_id) VALUES ('CS-190', 'CS-101')
INSERT INTO prereq (course_id, prereq_id) VALUES ('CS-315', 'CS-101')
INSERT INTO prereq (course_id, prereq_id) VALUES ('CS-319', 'CS-101')
INSERT INTO prereq (course_id, prereq_id) VALUES ('CS-347', 'CS-101')
INSERT INTO prereq (course_id, prereq_id) VALUES ('EE-181', 'PHY-101')

GO

INSERT INTO section (course_id, sec_id, semester, year, building, room_number, time_slot_id) VALUES ('BIO-101', '1', 'Summer', 2017, 'Painter', 514, 'B')
INSERT INTO section (course_id, sec_id, semester, year, building, room_number, time_slot_id) VALUES ('BIO-301', '1', 'Summer', 2018, 'Painter', 514, 'A')
INSERT INTO section (course_id, sec_id, semester, year, building, room_number, time_slot_id) VALUES ('CS-101', '1', 'Fall', 2017, 'Packard', 101, 'H')
INSERT INTO section (course_id, sec_id, semester, year, building, room_number, time_slot_id) VALUES ('CS-101', '1', 'Spring', 2018, 'Packard', 101, 'F')
INSERT INTO section (course_id, sec_id, semester, year, building, room_number, time_slot_id) VALUES ('CS-190', '1', 'Spring', 2017, 'Taylor', 3128, 'E')
INSERT INTO section (course_id, sec_id, semester, year, building, room_number, time_slot_id) VALUES ('CS-190', '2', 'Spring', 2017, 'Taylor', 3128, 'A')
INSERT INTO section (course_id, sec_id, semester, year, building, room_number, time_slot_id) VALUES ('CS-315', '1', 'Spring', 2018, 'Watson', 120, 'D')
INSERT INTO section (course_id, sec_id, semester, year, building, room_number, time_slot_id) VALUES ('CS-319', '1', 'Spring', 2018, 'Watson', 100, 'B')
INSERT INTO section (course_id, sec_id, semester, year, building, room_number, time_slot_id) VALUES ('CS-319', '2', 'Spring', 2018, 'Taylor', 3128, 'C')
INSERT INTO section (course_id, sec_id, semester, year, building, room_number, time_slot_id) VALUES ('CS-347', '1', 'Fall', 2017, 'Taylor', 3128, 'A')
INSERT INTO section (course_id, sec_id, semester, year, building, room_number, time_slot_id) VALUES ('EE-181', '1', 'Spring', 2017, 'Taylor', 3128, 'C')
INSERT INTO section (course_id, sec_id, semester, year, building, room_number, time_slot_id) VALUES ('FIN-201', '1', 'Spring', 2018, 'Packard', 101, 'B')
INSERT INTO section (course_id, sec_id, semester, year, building, room_number, time_slot_id) VALUES ('HIS-351', '1', 'Spring', 2018, 'Painter', 514, 'C')
INSERT INTO section (course_id, sec_id, semester, year, building, room_number, time_slot_id) VALUES ('MU-199', '1', 'Spring', 2018, 'Packard', 101, 'D')
INSERT INTO section (course_id, sec_id, semester, year, building, room_number, time_slot_id) VALUES ('PHY-101', '1', 'Fall', 2017, 'Watson', 100, 'A')

Go

INSERT INTO time_slot (time_slot_id, day, start_time, end_time) VALUES ('A', 'F', '08:00:00', '08:50:00')
INSERT INTO time_slot (time_slot_id, day, start_time, end_time) VALUES ('A', 'M', '08:00:00', '08:50:00')
INSERT INTO time_slot (time_slot_id, day, start_time, end_time) VALUES ('A', 'W', '08:00:00', '08:50:00')
INSERT INTO time_slot (time_slot_id, day, start_time, end_time) VALUES ('B', 'F', '09:00:00', '09:50:00')
INSERT INTO time_slot (time_slot_id, day, start_time, end_time) VALUES ('B', 'M', '09:00:00', '09:50:00')
INSERT INTO time_slot (time_slot_id, day, start_time, end_time) VALUES ('B', 'W', '09:00:00', '09:50:00')
INSERT INTO time_slot (time_slot_id, day, start_time, end_time) VALUES ('C', 'F', '11:00:00', '11:50:00')
INSERT INTO time_slot (time_slot_id, day, start_time, end_time) VALUES ('C', 'M', '11:00:00', '11:50:00')
INSERT INTO time_slot (time_slot_id, day, start_time, end_time) VALUES ('C', 'W', '11:00:00', '11:50:00')
INSERT INTO time_slot (time_slot_id, day, start_time, end_time) VALUES ('D', 'F', '13:00:00', '13:50:00')
INSERT INTO time_slot (time_slot_id, day, start_time, end_time) VALUES ('D', 'M', '13:00:00', '13:50:00')
INSERT INTO time_slot (time_slot_id, day, start_time, end_time) VALUES ('D', 'W', '13:00:00', '13:50:00')
INSERT INTO time_slot (time_slot_id, day, start_time, end_time) VALUES ('E', 'R', '10:30:00', '11:45:00')
INSERT INTO time_slot (time_slot_id, day, start_time, end_time) VALUES ('E', 'T', '10:30:00', '11:45:00')
INSERT INTO time_slot (time_slot_id, day, start_time, end_time) VALUES ('F', 'R', '14:30:00', '15:45:00')
INSERT INTO time_slot (time_slot_id, day, start_time, end_time) VALUES ('F', 'T', '14:30:00', '15:45:00')
INSERT INTO time_slot (time_slot_id, day, start_time, end_time) VALUES ('G', 'F', '16:00:00', '16:50:00')
INSERT INTO time_slot (time_slot_id, day, start_time, end_time) VALUES ('G', 'M', '16:00:00', '16:50:00')
INSERT INTO time_slot (time_slot_id, day, start_time, end_time) VALUES ('G', 'W', '16:00:00', '16:50:00')
INSERT INTO time_slot (time_slot_id, day, start_time, end_time) VALUES ('H', 'W', '10:00:00', '12:30:00')

GO



INSERT INTO takes (ID, course_id, sec_id, semester, year, grade) VALUES (128, 'CS-101', '1', 'Fall', 2017, 'A')
INSERT INTO takes (ID, course_id, sec_id, semester, year, grade) VALUES (128, 'CS-347', '1', 'Fall', 2017, 'A-')
INSERT INTO takes (ID, course_id, sec_id, semester, year, grade) VALUES (12345, 'CS-101', '1', 'Fall', 2017, 'C')
INSERT INTO takes (ID, course_id, sec_id, semester, year, grade) VALUES (12345, 'CS-190', '2', 'Spring', 2017, 'A')
INSERT INTO takes (ID, course_id, sec_id, semester, year, grade) VALUES (12345, 'CS-315', '1', 'Spring', 2018, 'A')
INSERT INTO takes (ID, course_id, sec_id, semester, year, grade) VALUES (12345, 'CS-347', '1', 'Fall', 2017, 'A')
INSERT INTO takes (ID, course_id, sec_id, semester, year, grade) VALUES (19991, 'HIS-351', '1', 'Spring', 2018, 'B')
INSERT INTO takes (ID, course_id, sec_id, semester, year, grade) VALUES (23121, 'FIN-201', '1', 'Spring', 2018, 'C+')
INSERT INTO takes (ID, course_id, sec_id, semester, year, grade) VALUES (44553, 'PHY-101', '1', 'Fall', 2017, 'B-')
INSERT INTO takes (ID, course_id, sec_id, semester, year, grade) VALUES (45678, 'CS-101', '1', 'Fall', 2017, 'F')
INSERT INTO takes (ID, course_id, sec_id, semester, year, grade) VALUES (45678, 'CS-101', '1', 'Spring', 2018, 'B+')
INSERT INTO takes (ID, course_id, sec_id, semester, year, grade) VALUES (45678, 'CS-319', '1', 'Spring', 2018, 'B')
INSERT INTO takes (ID, course_id, sec_id, semester, year, grade) VALUES (54321, 'CS-101', '1', 'Fall', 2017, 'A-')
INSERT INTO takes (ID, course_id, sec_id, semester, year, grade) VALUES (54321, 'CS-190', '2', 'Spring', 2017, 'B+')
INSERT INTO takes (ID, course_id, sec_id, semester, year, grade) VALUES (55739, 'MU-199', '1', 'Spring', 2018, 'A-')
INSERT INTO takes (ID, course_id, sec_id, semester, year, grade) VALUES (76543, 'CS-101', '1', 'Fall', 2017, 'A')
INSERT INTO takes (ID, course_id, sec_id, semester, year, grade) VALUES (76543, 'CS-319', '2', 'Spring', 2018, 'A')
INSERT INTO takes (ID, course_id, sec_id, semester, year, grade) VALUES (76653, 'EE-181', '1', 'Spring', 2017, 'C')
INSERT INTO takes (ID, course_id, sec_id, semester, year, grade) VALUES (98765, 'CS-101', '1', 'Fall', 2017, 'C-')
INSERT INTO takes (ID, course_id, sec_id, semester, year, grade) VALUES (98765, 'CS-315', '1', 'Spring', 2018, 'B')
INSERT INTO takes (ID, course_id, sec_id, semester, year, grade) VALUES (98988, 'BIO-101', '1', 'Summer', 2017, 'A')
INSERT INTO takes (ID, course_id, sec_id, semester, year, grade) VALUES (98988, 'BIO-301', '1', 'Summer', 2018, NULL)

GO

INSERT INTO teaches (ID, course_id, sec_id, semester, year) VALUES (10101, 'CS-101', '1', 'Fall', 2017)
INSERT INTO teaches (ID, course_id, sec_id, semester, year) VALUES (10101, 'CS-315', '1', 'Spring', 2018)
INSERT INTO teaches (ID, course_id, sec_id, semester, year) VALUES (10101, 'CS-347', '1', 'Fall', 2017)
INSERT INTO teaches (ID, course_id, sec_id, semester, year) VALUES (12121, 'FIN-201', '1', 'Spring', 2018)
INSERT INTO teaches (ID, course_id, sec_id, semester, year) VALUES (15151, 'MU-199', '1', 'Spring', 2018)
INSERT INTO teaches (ID, course_id, sec_id, semester, year) VALUES (22222, 'PHY-101', '1', 'Fall', 2017)
INSERT INTO teaches (ID, course_id, sec_id, semester, year) VALUES (32343, 'HIS-351', '1', 'Spring', 2018)
INSERT INTO teaches (ID, course_id, sec_id, semester, year) VALUES (45565, 'CS-101', '1', 'Spring', 2018)
INSERT INTO teaches (ID, course_id, sec_id, semester, year) VALUES (45565, 'CS-319', '1', 'Spring', 2018)
INSERT INTO teaches (ID, course_id, sec_id, semester, year) VALUES (76766, 'BIO-101', '1', 'Summer', 2017)
INSERT INTO teaches (ID, course_id, sec_id, semester, year) VALUES (76766, 'BIO-301', '1', 'Summer', 2018)
INSERT INTO teaches (ID, course_id, sec_id, semester, year) VALUES (83821, 'CS-190', '1', 'Spring', 2017)
INSERT INTO teaches (ID, course_id, sec_id, semester, year) VALUES (83821, 'CS-190', '2', 'Spring', 2017)
INSERT INTO teaches (ID, course_id, sec_id, semester, year) VALUES (83821, 'CS-319', '2', 'Spring', 2018)
INSERT INTO teaches (ID, course_id, sec_id, semester, year) VALUES (98345, 'EE-181', '1', 'Spring', 2017)

GO



Use University_database_1;

select * from department
select * from student

go

alter table student
drop constraint St_FK

alter table student
add constraint St_FK foreign key (dept_name) references department(dept_name)
ON DELETE CASCADE;




ALTER TABLE advisor
DROP CONSTRAINT ad_FK1;

ALTER TABLE advisor
ADD CONSTRAINT ad_FK1 FOREIGN KEY (s_id) REFERENCES student(ID)
ON DELETE CASCADE;


ALTER TABLE advisor
DROP CONSTRAINT ad_FK2;

ALTER TABLE advisor
ADD CONSTRAINT ad_FK2 FOREIGN KEY (i_id) REFERENCES instructor(ID)
ON DELETE CASCADE;

ALTER TABLE course
DROP CONSTRAINT FK_course_department;

ALTER TABLE course
ADD CONSTRAINT FK_course FOREIGN KEY (dept_name) REFERENCES department(dept_name)
ON DELETE CASCADE;

ALTER TABLE instructor
DROP CONSTRAINT ins_FK;

ALTER TABLE instructor
ADD CONSTRAINT ins_FK FOREIGN KEY (dept_name) REFERENCES department(dept_name)
ON DELETE CASCADE;

ALTER TABLE prereq
DROP CONSTRAINT FK__prereq__course_i__6FE99F9F;

ALTER TABLE prereq
ADD CONSTRAINT FK_prereq_course FOREIGN KEY (course_id) REFERENCES course(course_id)
ON DELETE CASCADE;


ALTER TABLE prereq
DROP CONSTRAINT FK__prereq__prereq_i__70DDC3D8;

ALTER TABLE prereq
ADD CONSTRAINT FK_prereq_prereq FOREIGN KEY (prereq_id) REFERENCES course(course_id)
ON DELETE CASCADE;

ALTER TABLE section
DROP CONSTRAINT FK__section__course___778AC167;

ALTER TABLE section
ADD CONSTRAINT FK_section_course FOREIGN KEY (course_id) REFERENCES course(course_id)
ON DELETE CASCADE;


ALTER TABLE section
DROP CONSTRAINT sec_FK;

ALTER TABLE section
ADD CONSTRAINT sec_FK FOREIGN KEY (building, room_number) REFERENCES classroom(building, room_number)
ON DELETE CASCADE;

ALTER TABLE takes
DROP CONSTRAINT FK__takes__ID__7C4F7684;

ALTER TABLE takes
ADD CONSTRAINT FK_takes_student FOREIGN KEY (ID) REFERENCES student(ID)
ON DELETE CASCADE;


ALTER TABLE takes
DROP CONSTRAINT takes_FK;

ALTER TABLE takes 
ADD CONSTRAINT takes_FK 
FOREIGN KEY (course_id, sec_id, semester, year) REFERENCES section(course_id, sec_id, semester, year) 
ON DELETE CASCADE ON UPDATE CASCADE;
GO

ALTER TABLE teaches
DROP CONSTRAINT FK__teaches__ID__01142BA1;

ALTER TABLE teaches
ADD CONSTRAINT FK_teaches_instructor FOREIGN KEY (ID) REFERENCES instructor(ID)
ON DELETE CASCADE;


ALTER TABLE teaches
DROP CONSTRAINT teaches_FK;

ALTER TABLE teaches
ADD CONSTRAINT teaches_FK FOREIGN KEY (course_id, sec_id, semester, year) REFERENCES section(course_id, sec_id, semester, year)
ON DELETE CASCADE;

Delete from department
where dept_name = 'Comp. Sci.'

select * from department
select * from student


ALTER TABLE course DROP CONSTRAINT FK_course;
ALTER TABLE course 
ADD CONSTRAINT FK_course_dept 
FOREIGN KEY (dept_name) REFERENCES department(dept_name) 
ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE student
DROP CONSTRAINT St_FK;

ALTER TABLE student 
ADD CONSTRAINT St_FK
FOREIGN KEY (dept_name) REFERENCES department(dept_name) 
ON UPDATE CASCADE 

UPDATE department 
SET dept_name = 'PHY' 
WHERE dept_name = 'Physics';

select * from department
select * from student