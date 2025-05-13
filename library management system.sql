-- Library Management System Database

-- Create database
CREATE DATABASE IF NOT EXISTS LibraryManagementSystem;
USE LibraryManagementSystem;

-- Members table (1-M with Borrowings, 1-M with Reservations)
CREATE TABLE Members (
    member_id INT AUTO_INCREMENT PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    phone VARCHAR(20),
    address TEXT,
    date_of_birth DATE,
    membership_date DATE NOT NULL,
    membership_expiry DATE NOT NULL,
    status ENUM('Active', 'Suspended', 'Expired') DEFAULT 'Active',
    CONSTRAINT chk_expiry CHECK (membership_expiry > membership_date)
);

-- Authors table (M-M with Books through BookAuthors)
CREATE TABLE Authors (
    author_id INT AUTO_INCREMENT PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    birth_year YEAR,
    death_year YEAR,
    nationality VARCHAR(50),
    biography TEXT,
    CONSTRAINT chk_lifespan CHECK (death_year IS NULL OR death_year >= birth_year)
);

-- Publishers table (1-M with Books)
CREATE TABLE Publishers (
    publisher_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    address TEXT,
    contact_email VARCHAR(100),
    contact_phone VARCHAR(20),
    website VARCHAR(100),
    established_year YEAR
);

-- Books table (1-M with BookCopies, M-M with Authors, M-M with Genres)
CREATE TABLE Books (
    book_id INT AUTO_INCREMENT PRIMARY KEY,
    title VARCHAR(200) NOT NULL,
    publisher_id INT,
    publication_year YEAR,
    isbn VARCHAR(20) UNIQUE,
    edition VARCHAR(10),
    description TEXT,
    page_count INT,
    language VARCHAR(30),
    CONSTRAINT fk_book_publisher FOREIGN KEY (publisher_id) 
        REFERENCES Publishers(publisher_id) ON DELETE SET NULL,
    CONSTRAINT chk_publication_year CHECK (publication_year <= YEAR(CURRENT_DATE))
);

-- BookAuthors table (junction table for M-M relationship between Books and Authors)
CREATE TABLE BookAuthors (
    book_id INT NOT NULL,
    author_id INT NOT NULL,
    PRIMARY KEY (book_id, author_id),
    CONSTRAINT fk_ba_book FOREIGN KEY (book_id) 
        REFERENCES Books(book_id) ON DELETE CASCADE,
    CONSTRAINT fk_ba_author FOREIGN KEY (author_id) 
        REFERENCES Authors(author_id) ON DELETE CASCADE
);

-- Genres table (M-M with Books through BookGenres)
CREATE TABLE Genres (
    genre_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(50) NOT NULL UNIQUE,
    description TEXT
);

-- BookGenres table (junction table for M-M relationship between Books and Genres)
CREATE TABLE BookGenres (
    book_id INT NOT NULL,
    genre_id INT NOT NULL,
    PRIMARY KEY (book_id, genre_id),
    CONSTRAINT fk_bg_book FOREIGN KEY (book_id) 
        REFERENCES Books(book_id) ON DELETE CASCADE,
    CONSTRAINT fk_bg_genre FOREIGN KEY (genre_id) 
        REFERENCES Genres(genre_id) ON DELETE CASCADE
);

-- BookCopies table (1-M with Borrowings)
CREATE TABLE BookCopies (
    copy_id INT AUTO_INCREMENT PRIMARY KEY,
    book_id INT NOT NULL,
    acquisition_date DATE NOT NULL,
    status ENUM('Available', 'Checked Out', 'Lost', 'Damaged', 'In Repair') DEFAULT 'Available',
    location VARCHAR(50) NOT NULL,
    notes TEXT,
    CONSTRAINT fk_copy_book FOREIGN KEY (book_id) 
        REFERENCES Books(book_id) ON DELETE CASCADE,
    CONSTRAINT chk_acquisition_date CHECK (acquisition_date <= CURRENT_DATE)
);

-- Borrowings table (1-M with Fines)
CREATE TABLE Borrowings (
    borrowing_id INT AUTO_INCREMENT PRIMARY KEY,
    copy_id INT NOT NULL,
    member_id INT NOT NULL,
    checkout_date DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    due_date DATE NOT NULL,
    return_date DATETIME,
    status ENUM('Checked Out', 'Returned', 'Overdue', 'Lost') DEFAULT 'Checked Out',
    CONSTRAINT fk_borrowing_copy FOREIGN KEY (copy_id) 
        REFERENCES BookCopies(copy_id) ON DELETE RESTRICT,
    CONSTRAINT fk_borrowing_member FOREIGN KEY (member_id) 
        REFERENCES Members(member_id) ON DELETE CASCADE,
    CONSTRAINT chk_due_date CHECK (due_date > DATE(checkout_date)),
    CONSTRAINT chk_return_date CHECK (return_date IS NULL OR return_date >= checkout_date)
);

-- Fines table
CREATE TABLE Fines (
    fine_id INT AUTO_INCREMENT PRIMARY KEY,
    borrowing_id INT NOT NULL,
    amount DECIMAL(10,2) NOT NULL,
    issue_date DATE NOT NULL,
    payment_date DATE,
    status ENUM('Pending', 'Paid', 'Waived') DEFAULT 'Pending',
    reason TEXT NOT NULL,
    CONSTRAINT fk_fine_borrowing FOREIGN KEY (borrowing_id) 
        REFERENCES Borrowings(borrowing_id) ON DELETE CASCADE,
    CONSTRAINT chk_amount CHECK (amount >= 0),
    CONSTRAINT chk_payment_date CHECK (payment_date IS NULL OR payment_date >= issue_date)
);

-- Reservations table
CREATE TABLE Reservations (
    reservation_id INT AUTO_INCREMENT PRIMARY KEY,
    book_id INT NOT NULL,
    member_id INT NOT NULL,
    reservation_date DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    expiry_date DATETIME NOT NULL,
    status ENUM('Pending', 'Fulfilled', 'Cancelled', 'Expired') DEFAULT 'Pending',
    CONSTRAINT fk_reservation_book FOREIGN KEY (book_id) 
        REFERENCES Books(book_id) ON DELETE CASCADE,
    CONSTRAINT fk_reservation_member FOREIGN KEY (member_id) 
        REFERENCES Members(member_id) ON DELETE CASCADE,
    CONSTRAINT chk_reservation_expiry CHECK (expiry_date > reservation_date)
);

-- Staff table
CREATE TABLE Staff (
    staff_id INT AUTO_INCREMENT PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    phone VARCHAR(20),
    address TEXT,
    position VARCHAR(50) NOT NULL,
    hire_date DATE NOT NULL,
    salary DECIMAL(10,2),
    CONSTRAINT chk_salary CHECK (salary >= 0),
    CONSTRAINT chk_hire_date CHECK (hire_date <= CURRENT_DATE)
);

-- Transactions table (for financial transactions)
CREATE TABLE Transactions (
    transaction_id INT AUTO_INCREMENT PRIMARY KEY,
    member_id INT,
    staff_id INT,
    transaction_date DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    amount DECIMAL(10,2) NOT NULL,
    transaction_type ENUM('Membership Fee', 'Fine Payment', 'Donation', 'Other') NOT NULL,
    payment_method ENUM('Cash', 'Credit Card', 'Debit Card', 'Check', 'Online') NOT NULL,
    description TEXT,
    CONSTRAINT fk_transaction_member FOREIGN KEY (member_id) 
        REFERENCES Members(member_id) ON DELETE SET NULL,
    CONSTRAINT fk_transaction_staff FOREIGN KEY (staff_id) 
        REFERENCES Staff(staff_id) ON DELETE SET NULL,
    CONSTRAINT chk_transaction_amount CHECK (amount > 0)
);

-- Create indexes for performance optimization
CREATE INDEX idx_book_title ON Books(title);
CREATE INDEX idx_member_name ON Members(last_name, first_name);
CREATE INDEX idx_author_name ON Authors(last_name, first_name);
CREATE INDEX idx_borrowing_dates ON Borrowings(checkout_date, due_date, return_date);
CREATE INDEX idx_copy_status ON BookCopies(status);
CREATE INDEX idx_fine_status ON Fines(status);