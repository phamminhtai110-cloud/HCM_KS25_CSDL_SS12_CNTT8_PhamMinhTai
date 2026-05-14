CREATE DATABASE QLSinhVien;
USE QLSinhVien;

-- =========================
-- 1. TẠO BẢNG
-- =========================

-- Bảng Khoa
CREATE TABLE Department (
    DeptID VARCHAR(5) PRIMARY KEY,
    DeptName VARCHAR(50) NOT NULL
);

-- Bảng SinhVien
CREATE TABLE Student (
    StudentID VARCHAR(6) PRIMARY KEY,
    FullName VARCHAR(50),
    Gender VARCHAR(10),
    BirthDate DATE,
    DeptID VARCHAR(5),
    FOREIGN KEY (DeptID) REFERENCES Department(DeptID)
);

-- Bảng MonHoc
CREATE TABLE Course (
    CourseID VARCHAR(6) PRIMARY KEY,
    CourseName VARCHAR(50),
    Credits INT
);

-- Bảng DangKy
CREATE TABLE Enrollment (
    StudentID VARCHAR(6),
    CourseID VARCHAR(6),
    Score DECIMAL(4,2),
    PRIMARY KEY (StudentID, CourseID),
    FOREIGN KEY (StudentID) REFERENCES Student(StudentID),
    FOREIGN KEY (CourseID) REFERENCES Course(CourseID)
);

-- =========================
-- 2. CHÈN DỮ LIỆU MẪU
-- =========================

INSERT INTO Department VALUES
('IT','Information Technology'),
('BA','Business Administration'),
('ACC','Accounting');

INSERT INTO Student VALUES
('S00001','Nguyen An','Male','2003-05-10','IT'),
('S00002','Tran Binh','Male','2003-06-15','IT'),
('S00003','Le Hoa','Female','2003-08-20','BA'),
('S00004','Pham Minh','Male','2002-12-12','ACC'),
('S00005','Vo Lan','Female','2003-03-01','IT'),
('S00006','Do Hung','Male','2002-11-11','BA'),
('S00007','Nguyen Mai','Female','2003-07-07','ACC'),
('S00008','Tran Phuc','Male','2003-09-09','IT');

INSERT INTO Course VALUES
('C00001','Database Systems',3),
('C00002','Programming',4),
('C00003','Marketing',3);

INSERT INTO Enrollment VALUES
('S00001','C00001',8.50),
('S00002','C00001',9.25),
('S00003','C00001',7.00),
('S00005','C00001',8.75),
('S00008','C00001',9.50),
('S00001','C00002',8.00),
('S00002','C00002',7.50),
('S00003','C00003',9.00);

-- =====================================================
-- PHẦN A – CƠ BẢN
-- =====================================================

-- ==========================================
-- CÂU 1
-- Tạo View ViewStudentBasic
-- ==========================================

CREATE VIEW ViewStudentBasic AS
SELECT 
    s.StudentID,
    s.FullName,
    d.DeptName
FROM Student s
JOIN Department d
ON s.DeptID = d.DeptID;

-- Truy vấn dữ liệu từ View
SELECT * FROM ViewStudentBasic;

-- ==========================================
-- CÂU 2
-- Tạo Regular Index
-- ==========================================

CREATE INDEX idxFullName
ON Student(FullName);

-- ==========================================
-- CÂU 3
-- Stored Procedure GetStudentsIT
-- ==========================================

DELIMITER //

CREATE PROCEDURE GetStudentsIT()
BEGIN
    SELECT 
        s.StudentID,
        s.FullName,
        s.Gender,
        s.BirthDate,
        d.DeptName
    FROM Student s
    JOIN Department d
        ON s.DeptID = d.DeptID
    WHERE d.DeptName = 'Information Technology';
END //

DELIMITER ;

-- Gọi Procedure
CALL GetStudentsIT();

-- =====================================================
-- PHẦN B – KHÁ
-- =====================================================

-- ==========================================
-- CÂU 4a
-- View đếm số sinh viên mỗi khoa
-- ==========================================

CREATE VIEW ViewStudentCountByDept AS
SELECT 
    d.DeptName,
    COUNT(s.StudentID) AS TotalStudents
FROM Department d
LEFT JOIN Student s
    ON d.DeptID = s.DeptID
GROUP BY d.DeptName;

-- Xem dữ liệu View
SELECT * FROM ViewStudentCountByDept;

-- ==========================================
-- CÂU 4b
-- Khoa có nhiều sinh viên nhất
-- ==========================================

SELECT *
FROM ViewStudentCountByDept
WHERE TotalStudents = (
    SELECT MAX(TotalStudents)
    FROM ViewStudentCountByDept
);

-- ==========================================
-- CÂU 5a
-- Procedure GetTopScoreStudent
-- ==========================================

DELIMITER //

CREATE PROCEDURE GetTopScoreStudent(
    IN varCourseID VARCHAR(6)
)
BEGIN
    SELECT 
        s.StudentID,
        s.FullName,
        c.CourseName,
        e.Score
    FROM Enrollment e
    JOIN Student s
        ON e.StudentID = s.StudentID
    JOIN Course c
        ON e.CourseID = c.CourseID
    WHERE e.CourseID = varCourseID
      AND e.Score = (
            SELECT MAX(Score)
            FROM Enrollment
            WHERE CourseID = varCourseID
      );
END //

DELIMITER ;

-- ==========================================
-- CÂU 5b
-- Tìm sinh viên điểm cao nhất môn C00001
-- ==========================================

CALL GetTopScoreStudent('C00001');

-- =====================================================
-- PHẦN C – GIỎI
-- =====================================================

-- ==========================================
-- CÂU 6a
-- Tạo View WITH CHECK OPTION
-- ==========================================

CREATE VIEW ViewITEnrollmentDB AS
SELECT
    e.StudentID,
    s.FullName,
    s.DeptID,
    e.CourseID,
    e.Score
FROM Enrollment e
JOIN Student s
    ON e.StudentID = s.StudentID
WHERE s.DeptID = 'IT'
  AND e.CourseID = 'C00001'
WITH CHECK OPTION;

-- Kiểm tra View
SELECT * FROM ViewITEnrollmentDB;

-- ==========================================
-- CÂU 6b
-- Procedure UpdateScoreITDB
-- ==========================================

DELIMITER //

CREATE PROCEDURE UpdateScoreITDB(
    IN varStudentID VARCHAR(6),
    INOUT inoutNewScore DECIMAL(4,2)
)
BEGIN

    -- Nếu điểm > 10 thì gán = 10
    IF inoutNewScore > 10 THEN
        SET inoutNewScore = 10;
    END IF;

    -- Cập nhật thông qua VIEW
    UPDATE ViewITEnrollmentDB
    SET Score = inoutNewScore
    WHERE StudentID = varStudentID;

END //

DELIMITER ;

-- ==========================================
-- CÂU 6c
-- Gọi Procedure kiểm tra
-- ==========================================

-- Tạo biến session
SET @newScore = 11;

-- Gọi procedure
CALL UpdateScoreITDB('S00001', @newScore);

-- Hiển thị giá trị sau khi xử lý
SELECT @newScore AS FinalScore;

-- Kiểm tra dữ liệu trong View
SELECT * FROM ViewITEnrollmentDB;