-- ==========================================
-- 1. SYSTEM SETTINGS & USERS
-- ==========================================

CREATE TABLE systemSettings (
    settingKey VARCHAR(100) PRIMARY KEY, 
    settingValue VARCHAR(255) NOT NULL,
    dataType VARCHAR(20) DEFAULT 'STRING', 
    description TEXT,
    updatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    CHECK (dataType IN ('BOOLEAN', 'INTEGER', 'STRING', 'DECIMAL'))
);

CREATE TABLE users ( 
    userId VARCHAR(64) PRIMARY KEY, 
    email VARCHAR(255) NOT NULL UNIQUE, 
    firstName VARCHAR(100) NOT NULL, 
    lastName VARCHAR(100) NOT NULL, 
    userRole VARCHAR(50) NOT NULL DEFAULT 'STUDENT', 
    emailVerified BOOLEAN DEFAULT FALSE, 
    isActive BOOLEAN DEFAULT TRUE, 
    lastActive TIMESTAMP NULL, 
    createdBy VARCHAR(64), 
    createdAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP, 

    CHECK (userRole IN ('ADMIN', 'TEACHER', 'STUDENT')) 
); 

-- ==========================================
-- 2. SESSIONS, LOGS & NOTIFICATIONS
-- ==========================================

CREATE TABLE sessions ( 
    sessionId VARCHAR(64) PRIMARY KEY, 
    userId VARCHAR(64) NOT NULL, 
    ipAddress VARCHAR(45), 
    userAgent TEXT, 
    isActive BOOLEAN DEFAULT TRUE, 
    isExempt BOOLEAN DEFAULT FALSE, 
    loginTime TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP, 
    lastActivity TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP, 
    logoutTime TIMESTAMP NULL, 
 
    CONSTRAINT fk_sessions_user 
        FOREIGN KEY (userId) 
        REFERENCES users(userId) 
        ON DELETE CASCADE 
); 

CREATE TABLE activityLogs ( 
    logId BIGINT AUTO_INCREMENT PRIMARY KEY, 
    userId VARCHAR(64) NOT NULL, 
    action VARCHAR(100) NOT NULL, 
    details TEXT, 
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP, 
 
    CONSTRAINT fk_logs_user 
        FOREIGN KEY (userId) 
        REFERENCES users(userId) 
        ON DELETE CASCADE 
); 

CREATE TABLE securityLogs (
    securityId VARCHAR(64) PRIMARY KEY, 
    userId VARCHAR(64) NULL,
    type VARCHAR(50) NOT NULL,
    severity VARCHAR(20) NOT NULL,
    description TEXT,
    ipAddress VARCHAR(45),
    userAgent TEXT,
    resolved BOOLEAN DEFAULT FALSE,
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_security_user 
        FOREIGN KEY (userId) 
        REFERENCES users(userId) 
        ON DELETE SET NULL
);

CREATE TABLE notifications (
    notificationId VARCHAR(64) PRIMARY KEY,
    userId VARCHAR(64) NOT NULL,
    type VARCHAR(50) NOT NULL, 
    title VARCHAR(255) NOT NULL,
    message TEXT NOT NULL,
    reason VARCHAR(255),
    referenceId VARCHAR(64) NULL, 
    referenceType VARCHAR(50) NULL, 
    isRead BOOLEAN DEFAULT FALSE,
    deletedBy VARCHAR(64) NULL,
    createdAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_notifications_user 
        FOREIGN KEY (userId) 
        REFERENCES users(userId) 
        ON DELETE CASCADE,
        
    CONSTRAINT fk_notifications_deletedBy
        FOREIGN KEY (deletedBy)
        REFERENCES users(userId)
        ON DELETE SET NULL
);

-- ==========================================
-- 3. CORE QUIZ CONTENT
-- ==========================================

CREATE TABLE quizzes ( 
    quizId VARCHAR(64) PRIMARY KEY, 
    title VARCHAR(255) NOT NULL, 
    description TEXT, 
    quizStatus VARCHAR(50) NOT NULL DEFAULT 'DRAFT', 
    isActive BOOLEAN DEFAULT TRUE, 
    createdBy VARCHAR(64) NOT NULL, 
    createdAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP, 
    updatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP, 
 
    CHECK (quizStatus IN ('DRAFT', 'PUBLISHED', 'ARCHIVED')), 
 
    CONSTRAINT fk_quizzes_creator 
        FOREIGN KEY (createdBy) 
        REFERENCES users(userId) 
        ON DELETE RESTRICT 
);

CREATE TABLE questions ( 
    questionId VARCHAR(64) PRIMARY KEY, 
    quizId VARCHAR(64) NOT NULL, 
    questionText TEXT NOT NULL, 
    questionType VARCHAR(50) NOT NULL DEFAULT 'MULTIPLE_CHOICE', 
    points DECIMAL(5,2) DEFAULT 1.00, 
    orderNum INT DEFAULT 1, 
    createdAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP, 
 
    CHECK (questionType IN ('MULTIPLE_CHOICE', 'TRUE_FALSE', 'IDENTIFICATION')), 
 
    CONSTRAINT fk_questions_quiz 
        FOREIGN KEY (quizId) 
        REFERENCES quizzes(quizId) 
        ON DELETE CASCADE 
); 

CREATE TABLE questionOptions ( 
    optionId VARCHAR(64) PRIMARY KEY, 
    questionId VARCHAR(64) NOT NULL, 
    optionText TEXT NOT NULL, 
    isCorrect BOOLEAN DEFAULT FALSE, 
    orderNum INT DEFAULT 1, 
 
    CONSTRAINT fk_options_question 
        FOREIGN KEY (questionId) 
        REFERENCES questions(questionId) 
        ON DELETE CASCADE 
); 

-- ==========================================
-- 4. QUIZ ASSIGNMENTS & TARGETING
-- ==========================================

CREATE TABLE quizAssignments (
    assignmentId VARCHAR(64) PRIMARY KEY,
    quizId VARCHAR(64) NOT NULL,
    assignmentType VARCHAR(50) NOT NULL DEFAULT 'ALL', 
    timeLimit INT, 
    deadline TIMESTAMP NULL, 
    assignedBy VARCHAR(64) NOT NULL,
    createdAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    CHECK (assignmentType IN ('ALL', 'SPECIFIC', 'GROUP')),
    
    CONSTRAINT fk_assignment_quiz
        FOREIGN KEY (quizId)
        REFERENCES quizzes(quizId)
        ON DELETE CASCADE,
        
    CONSTRAINT fk_assignment_user
        FOREIGN KEY (assignedBy)
        REFERENCES users(userId)
        ON DELETE RESTRICT
);

CREATE TABLE quizTargetStudents ( 
    id BIGINT AUTO_INCREMENT PRIMARY KEY, 
    assignmentId VARCHAR(64) NOT NULL, 
    studentId VARCHAR(64) NOT NULL, 
 
    CONSTRAINT uq_assignment_student 
        UNIQUE (assignmentId, studentId), 
 
    CONSTRAINT fk_qts_assignment 
        FOREIGN KEY (assignmentId) 
        REFERENCES quizAssignments(assignmentId) 
        ON DELETE CASCADE, 
 
    CONSTRAINT fk_qts_student 
        FOREIGN KEY (studentId) 
        REFERENCES users(userId) 
        ON DELETE CASCADE 
);

-- ==========================================
-- 5. QUIZ RESULTS & AI RECOMMENDATIONS
-- ==========================================

CREATE TABLE quizResults ( 
    resultId VARCHAR(64) PRIMARY KEY,
    assignmentId VARCHAR(64) NOT NULL, 
    quizId VARCHAR(64) NOT NULL, 
    studentId VARCHAR(64) NOT NULL, 
    score DECIMAL(6,2) NOT NULL DEFAULT 0.00, 
    maxScore DECIMAL(6,2) NOT NULL, 
    percentage DECIMAL(5,2) NOT NULL DEFAULT 0.00, 
    timeTaken INT NOT NULL, 
    quizStatus VARCHAR(50) NOT NULL DEFAULT 'IN_PROGRESS', 
    submittedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP, 
 
    CHECK (quizStatus IN ('IN_PROGRESS', 'COMPLETED')), 
    
    CONSTRAINT fk_results_assignment
        FOREIGN KEY (assignmentId)
        REFERENCES quizAssignments(assignmentId)
        ON DELETE RESTRICT,

    CONSTRAINT fk_results_quiz 
        FOREIGN KEY (quizId) 
        REFERENCES quizzes(quizId) 
        ON DELETE CASCADE, 
 
    CONSTRAINT fk_results_student 
        FOREIGN KEY (studentId) 
        REFERENCES users(userId) 
        ON DELETE CASCADE 
); 

CREATE TABLE quizresultAnswers ( 
    answerId BIGINT AUTO_INCREMENT PRIMARY KEY, 
    resultId VARCHAR(64) NOT NULL, 
    questionId VARCHAR(64) NOT NULL, 
    selectedOptionId VARCHAR(64) NULL, 
    textAnswer TEXT NULL, 
    isCorrect BOOLEAN NOT NULL DEFAULT FALSE, 
    points_awarded DECIMAL(5,2) DEFAULT 0.00, 
 
    CONSTRAINT fk_answers_result 
        FOREIGN KEY (resultId) 
        REFERENCES quizResults(resultId) 
        ON DELETE CASCADE, 
 
    CONSTRAINT fk_answers_question 
        FOREIGN KEY (questionId) 
        REFERENCES questions(questionId) 
        ON DELETE CASCADE, 
 
    CONSTRAINT fk_answers_option 
        FOREIGN KEY (selectedOptionId) 
        REFERENCES questionOptions(optionId) 
        ON DELETE SET NULL 
); 

CREATE TABLE aiRecommendations ( 
    recommendationId VARCHAR(64) PRIMARY KEY, 
    resultId VARCHAR(64) NOT NULL, 
    studentId VARCHAR(64) NOT NULL, 
    quizId VARCHAR(64) NOT NULL, 
    recommendations TEXT NOT NULL, 
    generatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP, 
 
    CONSTRAINT fk_ai_result 
        FOREIGN KEY (resultId) 
        REFERENCES quizResults(resultId) 
        ON DELETE CASCADE, 
 
    CONSTRAINT fk_ai_student 
        FOREIGN KEY (studentId) 
        REFERENCES users(userId) 
        ON DELETE CASCADE, 
 
    CONSTRAINT fk_ai_quiz 
        FOREIGN KEY (quizId) 
        REFERENCES quizzes(quizId) 
        ON DELETE CASCADE 
); 

CREATE TABLE aiRecommendationTopics ( 
    aitopicId BIGINT AUTO_INCREMENT PRIMARY KEY, 
    recommendationId VARCHAR(64) NOT NULL, 
    topicName VARCHAR(150) NOT NULL, 
 
    CONSTRAINT fk_topics_rec 
        FOREIGN KEY (recommendationId) 
        REFERENCES aiRecommendations(recommendationId) 
        ON DELETE CASCADE 
);
