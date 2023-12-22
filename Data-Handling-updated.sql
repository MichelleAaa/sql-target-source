-- This syntax works in PostgreSQL v15:

-- PART 1

-- Create Source and Target Tables:

CREATE TABLE target (
    id INT,
    value CHAR(1),
    PRIMARY KEY (id)
);

CREATE TABLE source (
    id INT,
    value CHAR(1),
    PRIMARY KEY (id)
);

-- Insert Data into Source and Target Tables:
INSERT INTO target (id, value) VALUES 
(1, 'A'), (2, 'A'), (3, NULL), (5, 'A'), (8, 'A'), (9, NULL), (10, NULL);

INSERT INTO source (id, value) VALUES 
(1, NULL), (2, 'B'), (4, 'B'), (8, 'B'), (9, 'B'), (10, NULL), (11, NULL);


-- PART 2

-- Update
CREATE TABLE result_update (
    id INT,
    value CHAR(1),
    PRIMARY KEY (id)
);

INSERT INTO result_update
SELECT * FROM target;

-- If there's a matching id in both the source and result_update tables, then the value field of the result_update table is updated to the value from the source table. If there is an id in the result_update table that is not in the source table, then no changes are made to the value field for that row.
UPDATE result_update t
SET value = s.value
FROM source s
WHERE t.id = s.id;


-- Merge
CREATE TABLE result_merge (
    id INT,
    value CHAR(1),
    PRIMARY KEY (id)
);

INSERT INTO result_merge
SELECT * FROM target;

-- If there's a matching id in both the source and result_merge tables, then the value field of the result_merge table is updated to the value from the source table. If there is an id in the result_merge table that is not in the source table, then no changes are made to the value field for that row.
UPDATE result_merge t
SET value = s.value
FROM source s
WHERE t.id = s.id;

-- Rows with ids that are in the source table but are not yet in the result_merge table will be added into the result_merge table.
INSERT INTO result_merge (id, value)
SELECT id, value
FROM source
WHERE source.id NOT IN (SELECT id FROM result_merge);


-- Append

-- In SQL the primary key must be unique. The result section requires two entries that list an id of 10 and value of NULL. An entry_id column has been added that will auto-generate unique values for the primary key so duplicate id/value pairs can exist in the same table.
CREATE TABLE result_append (
    entry_id SERIAL,
    id INT,
    value CHAR(1),
    PRIMARY KEY (entry_id)
);

INSERT INTO result_append (id, value)
SELECT * FROM target;

-- All id/value rows from the source table are added into the result_append table.
INSERT INTO result_append (id, value)
SELECT id, value FROM source;


-- Update Null Fill

CREATE TABLE result_update_null_fill (
    id INT,
    value CHAR(1),
    PRIMARY KEY (id)
);

INSERT INTO result_update_null_fill
SELECT * FROM target;

-- If the ids match in both tables and the value in the result_update_null_fill table is NULL, then the value in the result_update_null_fill table will be updated to the value from the source table.
UPDATE result_update_null_fill t
SET value = s.value
FROM source s
WHERE t.value IS NULL
AND t.id = s.id;


-- Merge Null Fill

CREATE TABLE result_merge_null_fill (
    id INT,
    value CHAR(1),
    PRIMARY KEY (id)
);

INSERT INTO result_merge_null_fill
SELECT * FROM target;

-- If the ids match in both tables and the value in the result_merge_null_fill table is NULL, then the value in the result_merge_null_fill table will be updated to the value from the source table.
UPDATE result_merge_null_fill t
SET value = s.value
FROM source s
WHERE t.value IS NULL
AND t.id = s.id;

-- If an id exists in the source table but doesn't exist in the result_merge_null_fill table, then that row will be copied into the result_merge_null_fill table.
INSERT INTO result_merge_null_fill (id, value)
SELECT id, value
FROM source
WHERE source.id NOT IN (SELECT id FROM result_merge_null_fill);


-- Update Override

CREATE TABLE result_update_override (
    id INT,
    value CHAR(1),
    PRIMARY KEY (id)
);

INSERT INTO result_update_override
SELECT * FROM target;


-- When the ids in both tables match and the value field of the source table is not NULL, then the value from the source table will be copied into the result_update_override table.
UPDATE result_update_override t
SET value = s.value
FROM source s
WHERE s.value IS NOT NULL
AND t.id = s.id;

-- Merge Override

CREATE TABLE result_merge_override (
    id INT,
    value CHAR(1),
    PRIMARY KEY (id)
);

INSERT INTO result_merge_override
SELECT * FROM target;

-- When the ids in both tables match and the value field of the source table is not NULL, then the value from the source table will be copied into the result_merge_override table.
UPDATE result_merge_override t
SET value = s.value
FROM source s
WHERE s.value IS NOT NULL
AND t.id = s.id;

-- When an id exists in the source table but is not yet in the result_merge_override table, then the id/value will be copied into the result_merge_override table.
-- INSERT INTO result_merge_override (id, value)
-- SELECT id, value
-- FROM source
-- WHERE source.id NOT IN (SELECT id FROM result_merge_override);


INSERT INTO result_merge_override (id, value)
SELECT source.id, source.value
FROM source
LEFT JOIN result_merge_override 
ON result_merge_override.id = source.id
WHERE result_merge_override.id IS NULL;


-- Output of the results:

SELECT * FROM result_update
ORDER BY id ASC;

SELECT * FROM result_merge
ORDER BY id ASC;

SELECT * FROM result_append
ORDER BY id ASC, value ASC;

SELECT * FROM result_update_null_fill
ORDER BY id ASC;

SELECT * FROM result_merge_null_fill
ORDER BY id ASC;

SELECT * FROM result_update_override
ORDER BY id ASC;

SELECT * FROM result_merge_override
ORDER BY id ASC;