CREATE DATABASE advanced_lab;

CREATE TABLE employees (
    emp_id      SERIAL PRIMARY KEY,
    first_name  VARCHAR(50)  NOT NULL,
    last_name   VARCHAR(50)  NOT NULL,
    department  VARCHAR(50)  DEFAULT 'General',
    salary      INTEGER      DEFAULT 30000,
    hire_date   DATE,
    status      VARCHAR(20)  DEFAULT 'Active'
);

CREATE TABLE departments (
    dept_id     SERIAL PRIMARY KEY,
    dept_name   VARCHAR(50) NOT NULL,
    budget      INTEGER,
    manager_id  INTEGER
);

CREATE TABLE projects (
    project_id    SERIAL PRIMARY KEY,
    project_name  VARCHAR(100) NOT NULL,
    dept_id       INTEGER REFERENCES departments(dept_id),
    start_date    DATE,
    end_date      DATE,
    budget        INTEGER
);

INSERT INTO employees (first_name, last_name, department, salary, hire_date, status) VALUES
    ('John',   'Smith',    'IT',    90000, '2018-03-15', 'Active'),
    ('Emma',   'Johnson',  'IT',    85000, '2019-07-01', 'Active'),
    ('Liam',   'Williams', 'IT',    70000, '2021-05-20', 'Active'),
    ('Olivia', 'Brown',    'Sales', 55000, '2017-11-11', 'Active'),
    ('Noah',   'Jones',    'Sales', 48000, '2022-02-14', 'Active'),
    ('Ava',    'Garcia',   'HR',    62000, '2016-09-30', 'Active'),
    ('Mason',  'Miller',   'HR',    45000, '2021-08-01', 'Inactive'),
    ('Sophia', 'Davis',    'Sales', 75000, '2022-01-10', 'Inactive'),
    ('Ethan',  'Wilson',   'IT',    52000, '2020-06-15', 'Terminated'),
    ('Tim',    'Newbie',   NULL,    35000, '2024-03-01', 'Active');

INSERT INTO employees (emp_id, first_name, last_name, department)
VALUES (100, 'Alice', 'Brown', 'IT');

INSERT INTO employees (first_name, last_name, salary, status)
VALUES ('Bob', 'Green', DEFAULT, DEFAULT);

INSERT INTO departments (dept_name, budget, manager_id) VALUES
    ('IT',    200000, 1),
    ('Sales', 120000, 4),
    ('Legal',  50000, NULL);

INSERT INTO projects (project_name, dept_id, start_date, end_date, budget) VALUES
    ('Legacy Migration', (SELECT dept_id FROM departments WHERE dept_name = 'IT'),    '2021-01-01', '2022-06-30', 40000),
    ('Website Redesign', (SELECT dept_id FROM departments WHERE dept_name = 'IT'),    '2024-01-01', '2026-12-31', 80000),
    ('Sales Portal',     (SELECT dept_id FROM departments WHERE dept_name = 'Sales'), '2024-05-01', '2026-10-31', 60000),
    ('Old Campaign',     (SELECT dept_id FROM departments WHERE dept_name = 'Sales'), '2020-01-01', '2022-12-31', 20000);

INSERT INTO employees (first_name, last_name, department, hire_date, salary)
VALUES ('Carol', 'White', 'HR', CURRENT_DATE, 50000 * 1.1);

CREATE TEMPORARY TABLE temp_employees (LIKE employees INCLUDING DEFAULTS);

INSERT INTO temp_employees
SELECT * FROM employees
WHERE department = 'IT';

SELECT * FROM temp_employees;

UPDATE employees
SET salary = ROUND(salary * 1.10)
WHERE salary IS NOT NULL;

UPDATE employees
SET status = 'Senior'
WHERE salary > 60000
  AND hire_date < '2020-01-01';

BEGIN;

UPDATE employees
SET department = CASE
                     WHEN salary > 80000 THEN 'Management'
                     WHEN salary BETWEEN 50000 AND 80000 THEN 'Senior'
                     ELSE 'Junior'
                 END
WHERE salary IS NOT NULL;

SELECT emp_id, first_name, salary, department FROM employees ORDER BY emp_id;

ROLLBACK;

UPDATE employees
SET department = DEFAULT
WHERE status = 'Inactive';

UPDATE departments d
SET budget = (SELECT ROUND(AVG(e.salary) * 1.2)
              FROM employees e
              WHERE e.department = d.dept_name)
WHERE EXISTS (SELECT 1
              FROM employees e
              WHERE e.department = d.dept_name
                AND e.salary IS NOT NULL);

UPDATE employees
SET salary = ROUND(salary * 1.15),
    status = 'Promoted'
WHERE department = 'Sales';

DELETE FROM employees
WHERE status = 'Terminated';

DELETE FROM employees
WHERE salary < 40000
  AND hire_date > '2023-01-01'
  AND department IS NULL;

DELETE FROM departments
WHERE dept_name NOT IN (SELECT DISTINCT department
                        FROM employees
                        WHERE department IS NOT NULL);

DELETE FROM projects
WHERE end_date < '2023-01-01'
RETURNING *;

INSERT INTO employees (first_name, last_name, department, salary, hire_date)
VALUES ('Nina', 'Nullable', NULL, NULL, CURRENT_DATE);

UPDATE employees
SET department = 'Unassigned'
WHERE department IS NULL;

DELETE FROM employees
WHERE salary IS NULL
   OR department IS NULL;

INSERT INTO employees (first_name, last_name, department, salary, hire_date)
VALUES ('David', 'Clark', 'Sales', 58000, CURRENT_DATE)
RETURNING emp_id, first_name || ' ' || last_name AS full_name;

UPDATE employees AS e
SET salary = e.salary + 5000
FROM (SELECT emp_id, salary AS old_salary FROM employees) AS old
WHERE e.emp_id = old.emp_id
  AND e.department = 'IT'
RETURNING e.emp_id, old.old_salary, e.salary AS new_salary;

DELETE FROM employees
WHERE hire_date < '2020-01-01'
RETURNING *;

INSERT INTO employees (first_name, last_name, department, salary, hire_date)
SELECT 'Alice', 'Brown', 'IT', 60000, CURRENT_DATE
WHERE NOT EXISTS (SELECT 1
                  FROM employees
                  WHERE first_name = 'Alice' AND last_name = 'Brown');

INSERT INTO employees (first_name, last_name, department, salary, hire_date)
SELECT 'Frank', 'Miller', 'IT', 60000, CURRENT_DATE
WHERE NOT EXISTS (SELECT 1
                  FROM employees
                  WHERE first_name = 'Frank' AND last_name = 'Miller');

UPDATE departments SET budget = 150000 WHERE dept_name = 'IT';
UPDATE departments SET budget =  80000 WHERE dept_name = 'Sales';

UPDATE employees e
SET salary = ROUND(e.salary * CASE
                                  WHEN (SELECT d.budget
                                        FROM departments d
                                        WHERE d.dept_name = e.department) > 100000
                                  THEN 1.10
                                  ELSE 1.05
                              END)
WHERE e.salary IS NOT NULL;

INSERT INTO employees (first_name, last_name, department, salary, hire_date) VALUES
    ('Batch1', 'Bulk', 'IT', 50000, CURRENT_DATE),
    ('Batch2', 'Bulk', 'IT', 52000, CURRENT_DATE),
    ('Batch3', 'Bulk', 'IT', 54000, CURRENT_DATE),
    ('Batch4', 'Bulk', 'IT', 56000, CURRENT_DATE),
    ('Batch5', 'Bulk', 'IT', 58000, CURRENT_DATE);

UPDATE employees
SET salary = ROUND(salary * 1.10)
WHERE last_name = 'Bulk'
RETURNING emp_id, first_name, salary;

BEGIN;

CREATE TABLE employee_archive (LIKE employees INCLUDING DEFAULTS);

INSERT INTO employee_archive
SELECT * FROM employees
WHERE status = 'Inactive';

DELETE FROM employees
WHERE status = 'Inactive';

COMMIT;

SELECT * FROM employee_archive;

UPDATE projects p
SET end_date = end_date + 30
WHERE p.budget > 50000
  AND (SELECT COUNT(*)
       FROM employees e
       JOIN departments d ON d.dept_name = e.department
       WHERE d.dept_id = p.dept_id) > 3
RETURNING project_id, project_name, end_date;
