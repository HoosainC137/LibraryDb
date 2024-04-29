--Section B
CREATE DATABASE TestLibrary;
USE TESTLibrary;

-- Create Authors table
CREATE TABLE Authors (
    AuthorID INT PRIMARY KEY,
    AuthorName VARCHAR(100) NOT NULL
);

-- Create Books table
CREATE TABLE Books (
    BookID INT PRIMARY KEY,
    Title VARCHAR(255) NOT NULL,
    AuthorID INT,
    ISBN VARCHAR(20),
    Genre VARCHAR(100),
    FOREIGN KEY (AuthorID) REFERENCES Authors(AuthorID)
);

-- Create Borrowers table
CREATE TABLE Borrowers (
    BorrowerID INT PRIMARY KEY,
    BorrowerName VARCHAR(100) NOT NULL,
    Email VARCHAR(100),
    Phone VARCHAR(20)
);

-- Create Loans table
CREATE TABLE Loans (
    LoanID INT PRIMARY KEY,
    BookID INT,
    BorrowerID INT,
    LoanDate DATE,
    ReturnDate DATE,
    FOREIGN KEY (BookID) REFERENCES Books(BookID),
    FOREIGN KEY (BorrowerID) REFERENCES Borrowers(BorrowerID)
);

-- Populate Authors table
INSERT INTO Authors (AuthorID, AuthorName)
VALUES 
    (1, 'Stephen King'),
    (2, 'J.K. Rowling'),
    (3, 'George Orwell'),
    (4, 'Harper Lee'),
    (5, 'Jane Austen');

-- Populate Books table
INSERT INTO Books (BookID, Title, AuthorID, ISBN, Genre)
VALUES 
    (1, 'The Shining', 1, '978-0307743657', 'Horror'),
    (2, 'Harry Potter and the Philosopher''s Stone', 2, '978-0747532743', 'Fantasy'),
    (3, 'IT', 1, '978-0451524935', 'Science Fiction'),
    (4, 'To Kill a Mockingbird', 4, '978-0061120084', 'Fiction'),
    (5, 'Pride and Prejudice', 5, '978-0141439518', 'Romance');

-- Populate Borrowers table
INSERT INTO Borrowers (BorrowerID, BorrowerName, Email, Phone)
VALUES 
    (1, 'John Doe', 'john@example.com', '123-456-7890'),
    (2, 'Jane Smith', 'jane@example.com', '987-654-3210'),
    (3, 'Alice Johnson', 'alice@example.com', '555-123-4567');

-- Populate Loans table
INSERT INTO Loans (LoanID, BookID, BorrowerID, LoanDate, ReturnDate)
VALUES 
    (1, 1, 1, '2024-04-01', '2024-04-15'),
    (2, 2, 2, '2024-04-02', '2024-04-16'),
    (3, 3, 3, '2024-04-03', '2024-04-17'),
    (4, 4, 1, '2024-04-04', NULL),
    (5, 5, 2, '2024-04-05', NULL);

-- Insert new records into the Books table
INSERT INTO Books (BookID, Title, AuthorID, ISBN, Genre)
VALUES 
    (6, 'The Great Gatsby', 2, '978-0743273565', 'Classic'),
    (7, 'The Catcher in the Rye', 1, '978-0316769488', 'Fiction'),
    (8, 'The Hobbit', 1, '978-0345534835', 'Fantasy'),
    (9, 'Lord of the Rings: The Fellowship of the Ring', 3, '978-0618640157', 'Fantasy'),
    (10, 'Brave New World', 5, '978-0060850524', 'Science Fiction');

select * from Authors
SELECT * FROM Books
SELECT * FROM Borrowers
SELECT * FROM Loans

--Write a query to retrieve all books by a specific author.
SELECT b.Title, a.AuthorName
FROM Books b
JOIN Authors a ON b.AuthorID = a.AuthorID
WHERE a.AuthorID = 1;

-- Update the information for a specific book loan
UPDATE Loans
SET ReturnDate = '2024-04-20'
WHERE LoanID = 1;

-- Delete a book record that is no longer available in the library
DELETE FROM Books
WHERE BookID = 10;

--SECTION C
--CREATE Table FineRates
CREATE TABLE FineRates (
    FineRateID INT PRIMARY KEY,
    FineRate DECIMAL(10, 2) -- Assuming fine rate is stored as decimal
);

INSERT INTO FineRates (FineRateID, FineRate) VALUES (1, 0.50); -- Example fine rate
select * from FineRates
-- Write the SQL code for calculating overdue fines for each outstanding loan, considering due date, loan date, and fine rate.
SELECT 
    l.LoanID,
    b.Title AS BookTitle,
    br.BorrowerName,
    l.LoanDate,
    l.ReturnDate AS ActualReturnDate,
    l.LoanDate AS DueDate,
    DATEDIFF(DAY, l.LoanDate, GETDATE()) AS DaysOverdue,
    DATEDIFF(DAY, l.LoanDate, GETDATE()) * f.FineRate AS FineAmount
FROM 
    Loans l
INNER JOIN 
    Books b ON l.BookID = b.BookID
INNER JOIN 
    Borrowers br ON l.BorrowerID = br.BorrowerID
INNER JOIN 
    FineRates f ON f.FineRateID = 1
WHERE 
    l.ReturnDate IS NULL
    AND GETDATE() > l.LoanDate

--Implement logic to return the calculated fines, either as a result set or through output parameters.
CREATE PROCEDURE CalculateFines
AS
BEGIN
    SET NOCOUNT ON;

    SELECT 
        l.LoanID,
        b.Title AS BookTitle,
        br.BorrowerName,
        l.LoanDate,
        l.ReturnDate AS ActualReturnDate,
        l.LoanDate AS DueDate,
        DATEDIFF(DAY, l.LoanDate, GETDATE()) AS DaysOverdue,
        DATEDIFF(DAY, l.LoanDate, GETDATE()) * f.FineRate AS FineAmount
    FROM 
        Loans l
    INNER JOIN 
        Books b ON l.BookID = b.BookID
    INNER JOIN 
        Borrowers br ON l.BorrowerID = br.BorrowerID
    INNER JOIN 
        FineRates f ON f.FineRateID = 1
    WHERE 
        l.ReturnDate IS NULL
        AND GETDATE() > l.LoanDate;
END;

--stored procedure to get the calculated fines for outstanding loans
EXEC CalculateFines;

--add new column AvailableCoppies and TotalCopies to books table
ALTER TABLE Books
ADD AvailableCopies INT;

ALTER TABLE Books
ADD TotalCopies INT;

SELECT * FROM Books



--Implement a trigger in SSMS that automatically updates the number of available copies whenever a book is loaned or returned.
CREATE TRIGGER UpdateAvailableCopies
ON Loans
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    DECLARE @BookID INT;
    
    -- Capture the BookID affected by the operation
    IF EXISTS(SELECT * FROM inserted)
        SELECT @BookID = BookID FROM inserted;
    ELSE
        SELECT @BookID = BookID FROM deleted;

    -- Update the number of available copies
    UPDATE Books
    SET AvailableCopies = TotalCopies - (
        SELECT COUNT(*)
        FROM Loans
        WHERE BookID = @BookID AND ReturnDate IS NULL
    )
    WHERE BookID = @BookID;
END;

--View Trigger
SELECT 
    name AS TriggerName,
    OBJECT_DEFINITION(OBJECT_ID) AS TriggerDefinition
FROM 
    sys.triggers
WHERE 
    name = 'UpdateAvailableCopies';

--Create index for Books tables
CREATE INDEX IX_Books_Title ON Books (Title);

-- Query to view the indexes in the database
SELECT *FROM sys.indexes
WHERE object_id = OBJECT_ID('Books'); 


